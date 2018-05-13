require "support/database"
require "tempfile"

RSpec.describe Backhoe::Mysql do
  let(:config) { YAML.load_file("spec/support/database.yml") }
  let(:database) { Database.new(config) }
  let(:file_path) { Tempfile.new.path }

  subject do
    described_class.new(config, file_path)
  end

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
  create_table "posts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.text "body"
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
  create_table "posts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.text "body"
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "name"
    t.string "email"
  end

        SCHEMA
      end

      it "doesn't stomp on :skip_tables option" do
        subject.dump skip_tables: [:posts], skip_columns: { users: [:passhash] }
        database.load_file file_path
        expect(database.schema).to eq <<-SCHEMA
  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
  create_table "posts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.text "body"
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "name"
    t.string "email"
    t.string "passhash"
  end

      SCHEMA
    end
  end
end

