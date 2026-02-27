require "backhoe/load"
require "backhoe/database"
require "support/database"
require "yaml"
require "tempfile"

RSpec.describe Backhoe::Load do
  let(:config) { YAML.load_file("spec/support/database.yml")["postgresql"] }
  let(:database) { Database.new(config) }

  subject do
    described_class.new(Backhoe::Database.new(config), file_path)
  end

  describe "#call" do
    around do |example|
      database.create_db
      example.run
      database.destroy_db
    end

    def reference_schema
      database.create_db
      database.load_schema
      database.schema
    end

    describe "with file_path ending in .sql" do
      let(:file_path) { "spec/support/example_postgresql.sql" }

      it "loads the supplied file_path into the current database" do
        subject.call
        actual = database.schema
        expect(actual).to eq reference_schema
      end
    end

    describe "with file_path ending in .gz" do
      let(:file_path) { "spec/support/example_postgresql.sql.gz" }

      it "dumps and gzips the current database to the supplied file_path" do
        subject.call
        actual = database.schema
        expect(actual).to eq reference_schema
      end
    end

    describe "with drop_and_create option enabled" do
      let(:file_path) { "spec/support/example_postgresql.sql" }

      it "dumps and gzips the current database to the supplied file_path" do
        database.load_schema do
          create_table :comments do |t|
            t.integer :user_id
            t.string :text
          end
        end

        subject.drop_and_create = true
        subject.call
        actual = database.schema
        expect(actual).to eq reference_schema
      end
    end
  end
end

