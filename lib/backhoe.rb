require "backhoe/version"
require "rake"
require "fileutils"

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

  class Base < Struct.new(:config, :file_path)
    include Rake::DSL

    private

    def database
      config["database"]
    end
  end

  class Mysql < Base
    def dump skip_tables: []
      mysqldump = `which mysqldump`.strip
      raise RuntimeError, "Cannot find mysqldump." if mysqldump.blank?
      sh "#{mysqldump} --no-create-db --single-transaction --quick -e #{skip_table_options(skip_tables)} #{mysql_options} > #{file_path}"
    end

    def load
      mysql = `which mysql`.strip
      raise RuntimeError, "Cannot find mysql." if mysql.blank?
      sh "#{mysql} #{mysql_options} < #{file_path}"
    end

    private

    def skip_table_options skip_tables
      skip_tables.map do |table|
        "--ignore-table=#{config["database"]}.#{table}"
      end.join(" ")
    end
    
    def mysql_options
      options =  " -u #{config["username"]}"
      options += " -p'#{config["password"]}'" if config["password"]
      options += " -h #{config["host"]}"      if config["host"]
      options += " -S #{config["socket"]}"    if config["socket"]
      options += " '#{config["database"]}'"
    end
  end

  module MysqlSkipColumns
    def dump **options
      if skip_columns = options.delete(:skip_columns)
        SanitizedDatabase.new(skip_columns, file_path).dump do |skip_tables|
          super options.merge(skip_tables: skip_tables)
        end
      else
        super
      end
    end

    private

    class SanitizedDatabase < Struct.new(:config, :file_path)
      def dump
        with_sanitized_tables do
          yield skip_tables
        end
        skip_tables.each do |table|
          File.write file_path, "RENAME TABLE `sanitized_#{table}` TO `#{table}`;\n", mode: "a"
        end
      end

      private

      def skip_tables
        config.keys
      end

      def with_sanitized_tables
        ActiveRecord::Base.transaction do
          config.each do |table, columns|
            sanitized_table = "sanitized_#{table}"
            sql <<-SQL
              DROP TABLE IF EXISTS `#{sanitized_table}`;
              CREATE TABLE `#{sanitized_table}` LIKE `#{table}`;
              INSERT INTO `#{sanitized_table}` SELECT * FROM `#{table}`;
              ALTER TABLE `#{sanitized_table}` #{columns.map { |column| "DROP `#{column}`" }.join(", ")};
            SQL
          end

          yield

          config.each do |table, _|
            sql "DROP TABLE `sanitized_#{table}`"
          end
        end
      end

      def sql queries
        queries.split(";").select(&:present?).each do |query|
          ActiveRecord::Base.connection.execute query
        end
      end
    end
  end
  Mysql.prepend MysqlSkipColumns

  Mysql2 = Mysql

  class Sqlite3 < Base
    def dump **_
      FileUtils.cp database, file_path
    end

    def load
      FileUtils.cp file_path, database
    end
  end

  class Postgresql < Base
    def dump **_
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

