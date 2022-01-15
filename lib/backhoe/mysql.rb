require "backhoe/base"

module Backhoe
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
          options[:skip_tables] ||= []
          options[:skip_tables] += skip_tables
          super **options
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
          File.write file_path, "RENAME TABLE `sanitized_#{table}` TO `#{table}`;", mode: "a"
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
end

