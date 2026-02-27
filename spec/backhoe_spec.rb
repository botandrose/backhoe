require "tempfile"
require "timecop"
require "support/database"

RSpec.describe Backhoe do
  let(:config) { YAML.load_file("spec/support/database.yml")["test"] }
  let(:database) { Database.new(config) }

  before do
    stub_const "Rails", double(env: "test")
    ActiveRecord::Base.configurations = YAML.load_file("spec/support/database.yml")
  end

  around do |example|
    database.create_db
    database.load_schema
    example.run
    database.destroy_db
  end

  describe ".dump" do
    it "works" do
      Backhoe.dump Tempfile.new.path
    end
  end

  describe ".load" do
    it "works" do
      Backhoe.load "spec/support/example.sql", drop_and_create: true
    end
  end
end
