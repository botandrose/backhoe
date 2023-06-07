require "tempfile"
require "timecop"

RSpec.describe Backhoe do
  describe ".dump" do
    before do
      stub_const "Rails", double(env: "test")
      ActiveRecord::Base.configurations = YAML.load_file("spec/support/database.yml")
    end

    it "works" do
      Backhoe.dump Tempfile.new.path
    end
  end

  describe ".load" do
    before do
      stub_const "Rails", double(env: "test")
      ActiveRecord::Base.configurations = YAML.load_file("spec/support/database.yml")
    end

    it "works" do
      Backhoe.load "spec/support/example.sql", drop_and_create: true
    end
  end
end
