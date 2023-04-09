require "backhoe/version"
require "backhoe/mysql"
require "active_record"

module Backhoe
  mattr_accessor(:file_path) { "db/data.sql" }
    
  class << self
    def dump file_path: Backhoe.file_path, **options
      Mysql.new(database_config, file_path).dump **options
    end

    def load file_path: Backhoe.file_path
      Mysql.new(database_config, file_path).load
    end

    def backup s3_path
      require "time"
      filename = "#{Time.now.utc.iso8601}.sql.gz"
      path = "/tmp/#{filename}"
      dump file_path: path
      Kernel.system "aws s3 mv #{path} s3://#{s3_path}/#{filename}"
    end

    private

    def database_config
      configs = ActiveRecord::Base.configurations
      config = configs.configs_for(env_name: current_environment_name).first
      hash = if config.respond_to?(:configuration_hash)
        config.configuration_hash # rails 7
      else
        config.config # rails 6
      end
      HashWithIndifferentAccess.new(hash)
    end

    def current_environment_name
      [
        defined?(Rails) && Rails.env,
        ENV["RAILS_ENV"],
        "development",
      ].find(&:itself)
    end
  end
end

