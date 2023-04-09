require "rake/file_utils"
require "timecop"

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

  describe ".backup" do
    it "works" do
      Timecop.freeze(Time.utc(2008, 9, 1, 10, 5, 0)) do
        file_name = "2008-09-01T10:05:00Z.sql.gz"
        file_path = "/tmp/#{file_name}"
        expect(Backhoe).to receive(:dump).with(file_path: file_path)
        expect(Kernel).to receive(:system).with("aws s3 mv #{file_path} s3://bucket/project/#{file_name}")
        Backhoe.backup "bucket/project"
      end
    end
  end
end
