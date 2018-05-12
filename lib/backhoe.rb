require "backhoe/version"
require "rake"
require "fileutils"

module Backhoe
  mattr_accessor(:file_path) { "db/data.sql" }
    
  class << self
    def dump file_path: Backhoe.file_path
      autodetect_adapter.new(database_config, file_path).dump
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

  class Base < Struct.new(:config, :file_path)
    include Rake::DSL

    private

    def database
      config["database"]
    end
  end

  class Mysql < Base
    def dump
      mysqldump = `which mysqldump`.strip
      raise RuntimeError, "Cannot find mysqldump." if mysqldump.blank?
      sh "#{mysqldump} --no-create-db --single-transaction --quick -e #{mysql_options} > #{file_path}"
    end

    def load
      mysql = `which mysql`.strip
      raise RuntimeError, "Cannot find mysql." if mysql.blank?
      sh "#{mysql} #{mysql_options} < #{file_path}"
    end

    private
    
    def mysql_options
      options =  " -u #{config["username"]}"
      options += " -p'#{config["password"]}'" if config["password"]
      options += " -h #{config["host"]}"      if config["host"]
      options += " -S #{config["socket"]}"    if config["socket"]
      options += " '#{config["database"]}'"
    end
  end

  Mysql2 = Mysql

  class Sqlite3 < Base
    def dump
      FileUtils.cp database, file_path
    end

    def load
      FileUtils.cp file_path, database
    end
  end

  class Postgresql < Base
    def dump
      pg_dump = `which pg_dump`.strip
      raise RuntimeError, "Cannot find pg_dump." if pg_dump.blank?
      sh "#{pg_dump} -c -f#{file_path} #{database}"
    end

    def load
      psql = `which psql`.strip
      raise RuntimeError, "Cannot find psql." if psql.blank?
      sh "#{psql} -q -d#{database} -f#{file_path}"
    end
  end
end

