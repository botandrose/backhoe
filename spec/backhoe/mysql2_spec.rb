require "backhoe/mysql2"
require "support/database"
require "yaml"
require "tempfile"

RSpec.describe Backhoe::Mysql2 do
  let(:config) { YAML.load_file("spec/support/database.yml")["test"] }
  let(:database) { Database.new(config) }
  let(:file_path) { Tempfile.new.path }

  subject do
    described_class.new(config, file_path)
  end

  let(:options) {
    case ActiveRecord.version.approximate_recommendation
    when "~> 6.0" then 'options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade'
    else 'charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade'
    end
  }

  describe "#dump" do
    around do |example|
      database.create_db
      database.load_schema
      example.run
      database.destroy_db
    end

    describe "by default" do
      it "dumps the current database to the supplied file_path" do
        subject.dump
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
        subject.dump
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

    describe ":skip_tables" do
      it "skips the supplied tables from the dump" do
        subject.dump skip_tables: [:posts]
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

    describe ":skip_columns" do
      it "skips the supplied columns from the dump" do
        subject.dump skip_columns: { users: [:passhash] }
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
        subject.dump skip_tables: [:posts], skip_columns: { users: [:passhash] }
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

  describe "#load" do
    around do |example|
      database.create_db
      example.run
      database.destroy_db
    end

    describe "with file_path ending in .sql" do
      let(:file_path) { "spec/support/example.sql" }

      it "loads the supplied file_path into the current database" do
        subject.load
        expect(database.schema).to eq <<-SCHEMA
    create_table "posts", #{options.sub(/utf8\b/, "utf8mb4")} do |t|
      t.integer "user_id"
      t.text "body"
    end

    create_table "users", #{options.sub(/utf8\b/, "utf8mb4")} do |t|
      t.integer "name"
      t.string "email"
      t.string "passhash"
    end

        SCHEMA
      end
    end

    describe "with file_path ending in .gz" do
      let(:file_path) { "spec/support/example.sql.gz" }

      it "dumps and gzips the current database to the supplied file_path" do
        subject.load
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

  end
end

