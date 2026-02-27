require "backhoe/load"
require "backhoe/database"
require "support/database"
require "yaml"
require "tempfile"
require "fileutils"

RSpec.describe Backhoe::Load do
  let(:config) { YAML.load_file("spec/support/database.yml")["sqlite"] }
  let(:database) { Database.new(config) }

  subject do
    described_class.new(Backhoe::Database.new(config), file_path)
  end

  describe "#call" do
    let(:fixture_path) { "tmp/backhoe_load_fixture.sqlite3" }
    let(:fixture_gz_path) { "#{fixture_path}.gz" }

    before do
      fixture_config = config.merge("database" => fixture_path)
      fixture_db = Database.new(fixture_config)
      fixture_db.create_db
      fixture_db.load_schema
      system "gzip -c #{fixture_path} > #{fixture_gz_path}"
      ActiveRecord::Base.establish_connection(config)
    end

    around do |example|
      database.create_db
      example.run
      database.destroy_db
    end

    after do
      FileUtils.rm_f(fixture_path)
      FileUtils.rm_f(fixture_gz_path)
    end

    def reference_schema
      database.create_db
      database.load_schema
      database.schema
    end

    describe "with a plain file_path" do
      let(:file_path) { fixture_path }

      it "loads the supplied file_path into the current database" do
        subject.call
        actual = database.schema
        expect(actual).to eq reference_schema
      end
    end

    describe "with file_path ending in .gz" do
      let(:file_path) { fixture_gz_path }

      it "loads and decompresses the supplied file_path into the current database" do
        subject.call
        actual = database.schema
        expect(actual).to eq reference_schema
      end
    end

    describe "with drop_and_create option enabled" do
      let(:file_path) { fixture_path }

      it "replaces the database with the supplied file" do
        database.load_schema do
          create_table :comments do |t|
            t.integer :user_id
            t.string :text
          end
        end

        ActiveRecord::Base.connection.disconnect!
        subject.drop_and_create = true
        subject.call
        actual = database.schema
        expect(actual).to eq reference_schema
      end
    end
  end
end
