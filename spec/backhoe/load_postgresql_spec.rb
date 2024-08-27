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

  let(:options) {
    if database.postgresql?
      "force: :cascade"
    else
      case ActiveRecord.version.approximate_recommendation
      when "~> 6.0" then 'options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade'
      else 'charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade'
      end
    end
  }

  describe "#call" do
    around do |example|
      database.create_db
      example.run
      database.destroy_db
    end

    describe "with file_path ending in .sql" do
      let(:file_path) { "spec/support/example_postgresql.sql" }

      it "loads the supplied file_path into the current database" do
        subject.call
        expect(database.schema).to eq <<-SCHEMA.strip
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
      let(:file_path) { "spec/support/example_postgresql.sql.gz" }

      it "dumps and gzips the current database to the supplied file_path" do
        subject.call
        expect(database.schema).to eq <<-SCHEMA.strip
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
        expect(database.schema).to eq <<-SCHEMA.strip
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

