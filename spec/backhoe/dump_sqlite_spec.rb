require "backhoe/dump"
require "backhoe/database"
require "support/database"
require "yaml"
require "tempfile"

RSpec.describe Backhoe::Dump do
  let(:config) { YAML.load_file("spec/support/database.yml")["sqlite"] }
  let(:database) { Database.new(config) }

  subject do
    described_class.new(Backhoe::Database.new(config), file_path)
  end

  describe "#call" do
    let(:file_path) { Tempfile.new.path }

    around do |example|
      database.create_db
      database.load_schema
      example.run
      database.destroy_db
    end

    describe "by default" do
      it "dumps the current database to the supplied file_path" do
        subject.call
        database.load_file file_path
        expect(database.schema).to eq <<-SCHEMA.strip
  create_table "posts", force: :cascade do |t|
    t.text "body"
    t.integer "user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.integer "name"
    t.string "passhash"
  end
        SCHEMA
      end
    end

    describe "with file_path ending in .gz" do
      let(:file_path) { Tempfile.new(["db",".sql.gz"]).path }

      it "dumps and gzips the current database to the supplied file_path" do
        subject.call
        system "gunzip #{file_path}"
        database.load_file file_path.sub(".gz","")
        expect(database.schema).to eq <<-SCHEMA.strip
  create_table "posts", force: :cascade do |t|
    t.text "body"
    t.integer "user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.integer "name"
    t.string "passhash"
  end
        SCHEMA
      end
    end
  end
end
