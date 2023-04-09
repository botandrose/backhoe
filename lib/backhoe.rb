require "backhoe/version"
require "backhoe/dump"
require "backhoe/load"
require "backhoe/backup"
require "backhoe/database"
require "active_record"

module Backhoe
  mattr_accessor(:file_path) { "db/data.sql.gz" }
    
  class << self
    def dump file_path=Backhoe.file_path, skip_tables: [], skip_columns: {}
      Dump.new(Database.new, file_path, skip_tables, skip_columns).call
    end

    def load file_path=Backhoe.file_path, drop_and_create: false
      Load.new(Database.new, file_path, drop_and_create).call
    end

    def backup s3_path, access_key: nil, secret_key: nil
      Backup.new(s3_path, access_key, secret_key).call
    end
  end
end

