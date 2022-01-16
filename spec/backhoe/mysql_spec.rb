require "support/database"
require "yaml"
require "tempfile"

RSpec.describe Backhoe::Mysql do
  let(:config) { YAML.load_file("spec/support/database.yml")["test"] }
  let(:database) { Database.new(config) }
  let(:file_path) { Tempfile.new.path }

  subject do
    described_class.new(config, file_path)
  end

  let(:options) {
    case ActiveRecord.version.approximate_recommendation
    when "~> 5.1" then 'force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8"'
    when "~> 5.2" then 'options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade'
    when "~> 6.0" then 'options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade'
    else 'charset: "utf8mb4", force: :cascade'
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
end

