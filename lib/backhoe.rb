require "backhoe/version"
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

    def backup s3_path
      require "time"
      filename = "#{Time.now.utc.iso8601}.sql"
      path = "/tmp/#{filename}"
      dump file_path: path
      Kernel.system "gzip -9f #{path}"
      Kernel.system "aws s3 mv #{path}.gz s3://#{s3_path}/#{filename}.gz"
    end

    private

    def autodetect_adapter
      adapter = database_config["adapter"]
      require "backhoe/#{adapter}"
      const_get(adapter.camelize)
    end

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

