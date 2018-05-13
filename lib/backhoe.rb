require "backhoe/version"
require "backhoe/mysql"
require "backhoe/postgresql"
require "backhoe/sqlite"
require "active_record"

module Backhoe
  mattr_accessor(:file_path) { "db/data.sql" }
    
  class << self
    def dump file_path: Backhoe.file_path, **options
      autodetect_adapter.new(database_config, file_path).dump **options
    end

    def load file_path: Backhoe.file_path
      autodetect_adapter.new(database_config, file_path).load
    end

    private

    def autodetect_adapter
      const_get(database_config["adapter"].camelize)
    end

    def database_config
      ActiveRecord::Base.configurations[Rails.env || "development"]
    end
  end
end

