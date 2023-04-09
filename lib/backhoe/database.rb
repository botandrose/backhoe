module Backhoe
  class Database
    def initialize config=load_config
      @config = config
    end

    attr_reader :config 

    def current_environment_name
      [
        defined?(Rails) && Rails.env,
        ENV["RAILS_ENV"],
        "development",
      ].find(&:itself)
    end

    def to_mysql_options
      options =  " -u #{config["username"]}"
      options += " -p'#{config["password"]}'" if config["password"]
      options += " -h #{config["host"]}"      if config["host"]
      options += " -S #{config["socket"]}"    if config["socket"]
      options
    end

    def name
      config["database"]
    end

    private

    def load_config
      configs = ActiveRecord::Base.configurations
      config = configs.configs_for(env_name: current_environment_name).first
      hash = if config.respond_to?(:configuration_hash)
        config.configuration_hash # rails 7
      else
        config.config # rails 6
      end
      HashWithIndifferentAccess.new(hash)
    end
  end
end
