require "tempfile"

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
      options =  ""
      options += " --defaults-extra-file=#{password_file.path}" if config["password"]
      options += " -u #{config["username"]}"
      options += " -h #{config["host"]}"      if config["host"]
      options += " -S #{config["socket"]}"    if config["socket"]
      options
    end

    def name
      config["database"]
    end

    def adapter
      config["adapter"]
    end

    def postgresql?
      config["adapter"] == "postgresql"
    end

    def mysql?
      %w[mysql2 trilogy].include?(config["adapter"])
    end

    def sqlite?
      config["adapter"] == "sqlite3"
    end

    def path
      raise unless sqlite?
      config["database"]
    end

    private

    # A password on the command line is visible to every user on the host and echoed into logs and errors.
    def password_file
      @password_file ||= Tempfile.new(["backhoe", ".cnf"]).tap do |file|
        file.write(%([client]\npassword="#{config["password"].to_s.gsub(/[\\"]/) { "\\#{$&}" }}"\n))
        file.flush
      end
    end

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
