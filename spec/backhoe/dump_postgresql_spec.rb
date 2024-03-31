require "backhoe/dump"
require "backhoe/database"
require "support/database"
require "yaml"
require "tempfile"

RSpec.describe Backhoe::Dump do
  let(:config) { YAML.load_file("spec/support/database.yml")["postgresql"] }
  let(:database) { Database.new(config) }

  subject do
    described_class.new(Backhoe::Database.new(config), file_path)
  end

  let(:options) {
    if database.postgresql?
      'force: :cascade'
    else
      case ActiveRecord.version.approximate_recommendation
      when "~> 6.0" then 'options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade'
      else 'charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade'
      end
    end
  }

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
        expect(database.schema).to eq <<-SCHEMA
  create_table "posts", #{options} do |t|
    t.integer "user_id"
    t.text "body"
  end

  create_table "users", #{options} do |t|
    t.integer "name"
    t.string "email"
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
        expect(database.schema).to eq <<-SCHEMA
  create_table "posts", #{options} do |t|
    t.integer "user_id"
    t.text "body"
  end

  create_table "users", #{options} do |t|
    t.integer "name"
    t.string "email"
    t.string "passhash"
  end

        SCHEMA
      end
    end

    xdescribe ":skip_tables" do
      it "skips the supplied tables from the dump" do
        subject.skip_tables = [:posts]
        subject.call
        database.load_file file_path
        expect(database.schema).to eq <<-SCHEMA
  create_table "users", #{options} do |t|
    t.integer "name"
    t.string "email"
    t.string "passhash"
  end

        SCHEMA
      end
    end

    xdescribe ":skip_columns" do
      it "skips the supplied columns from the dump" do
        subject.skip_columns = { users: [:passhash] }
        subject.call
        database.load_file file_path
        expect(database.schema).to eq <<-SCHEMA
  create_table "posts", #{options} do |t|
    t.integer "user_id"
    t.text "body"
  end

  create_table "users", #{options} do |t|
    t.integer "name"
    t.string "email"
  end

        SCHEMA
      end

      it "doesn't stomp on :skip_tables option" do
        subject.skip_tables = [:posts]
        subject.skip_columns = { users: [:passhash] }
        subject.call
        database.load_file file_path
        expect(database.schema).to eq <<-SCHEMA
  create_table "users", #{options} do |t|
    t.integer "name"
    t.string "email"
  end

        SCHEMA
      end
    end
  end
end


