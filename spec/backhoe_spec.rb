require "rake/file_utils"

RSpec.describe Backhoe do
  describe ".dump" do
    let(:adapter) { spy }

    before do
      stub_const "Rails", double(env: "test")
      stub_const "Backhoe::Mysql2", adapter
      ActiveRecord::Base.configurations = YAML.load_file("spec/support/database.yml")
    end

    it "works" do
      expect(adapter).to receive(:new).with({
        "adapter"=>"mysql2",
        "database"=>"backhoe_test",
        "username"=>"root",
        "password"=>nil,
      }, "db/data.sql")
      Backhoe.dump
    end
  end
end
