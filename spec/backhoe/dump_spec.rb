require "backhoe/dump"
require "backhoe/database"
require "support/database"
require "support/fake_server"
require "yaml"
require "tempfile"

RSpec.describe Backhoe::Dump do
  let(:config) { YAML.load_file("spec/support/database.yml")["test"] }
  let(:database) { Database.new(config) }

  subject do
    described_class.new(Backhoe::Database.new(config), path)
  end

  let(:options) {
    case ActiveRecord.version.approximate_recommendation
    when "~> 6.0" then 'options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade'
    else 'charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade'
    end
  }

  let(:schema) { <<-SCHEMA.strip }
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

  describe "#call" do
    let(:path) { Tempfile.new.path }

    around do |example|
      database.create_db
      database.load_schema
      example.run
      database.destroy_db
    end

    describe "by default" do
      it "dumps the current database to the supplied path" do
        subject.call
        database.load_file path
        expect(database.schema).to eq schema
      end
    end

    describe "with path ending in .gz" do
      let(:path) { Tempfile.new(["db",".sql.gz"]).path }

      it "dumps and gzips the current database to the supplied path" do
        subject.call
        system "gunzip #{path}"
        database.load_file path.sub(".gz","")
        expect(database.schema).to eq schema
      end
    end

    context "remote" do
      let(:server) { FakeServer.new("tmp/fake_server/files") }

      around do |example|
        server.reset
        server.start
        example.run
        server.stop
      end

      describe "with path starting with http(s)://" do
        let(:path) { "http://localhost:#{server.port}/post" }

        it "dumps the current database and PUTs it to the supplied path" do
          subject.call
          database.load_file File.join(server.path, "/post")
          expect(database.schema).to eq schema
        end
      end

      describe "with path starting with http(s):// and ending with .gz" do
        let(:path) { "http://localhost:#{server.port}/database.sql.gz" }

        it "dumps and gzips the current database and PUTs it to the supplied path" do
          subject.call
          uploaded_file_path = File.join(server.path, "/database.sql.gz")
          system "gunzip #{uploaded_file_path}"
          database.load_file uploaded_file_path.sub(".gz","")
          expect(database.schema).to eq schema
        end
      end

      describe "with path starting with http(s):// and ending with .gz but with a query string" do
        let(:path) { "http://localhost:#{server.port}/database.sql.gz?query-string=true" }

        it "dumps and gzips the current database and PUTs it to the supplied path" do
          subject.call
          uploaded_file_path = File.join(server.path, "/database.sql.gz")
          system "gunzip #{uploaded_file_path}"
          database.load_file uploaded_file_path.sub(".gz","")
          expect(database.schema).to eq schema
        end
      end
    end

    describe ":skip_tables" do
      it "skips the supplied tables from the dump" do
        subject.skip_tables = [:posts]
        subject.call
        database.load_file path
        expect(database.schema).to eq <<-SCHEMA.strip
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
        subject.skip_columns = { users: [:passhash] }
        subject.call
        database.load_file path
        expect(database.schema).to eq <<-SCHEMA.strip
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
        database.load_file path
        expect(database.schema).to eq <<-SCHEMA.strip
  create_table "users", #{options} do |t|
    t.integer "name"
    t.string "email"
  end
        SCHEMA
      end
    end
  end
end

