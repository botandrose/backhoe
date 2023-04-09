require "backhoe/version"
require "backhoe/dump"
require "backhoe/load"
require "backhoe/database"
require "active_record"

module Backhoe
  mattr_accessor(:file_path) { "db/data.sql" }
    
  class << self
    def dump file_path: Backhoe.file_path, skip_tables: [], skip_columns: {}
      Dump.new(Database.new, file_path, skip_tables, skip_columns).call
    end

    def load file_path: Backhoe.file_path, drop_and_create: false
      Load.new(Database.new, file_path, drop_and_create).call
    end

    def backup s3_path
      require "time"
      filename = "#{Time.now.utc.iso8601}.sql.gz"
      path = "/tmp/#{filename}"
      dump file_path: path
      Kernel.system "aws s3 mv #{path} s3://#{s3_path}/#{filename}"
    end
  end
end

