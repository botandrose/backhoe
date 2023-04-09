require "rake"

module Backhoe
  class Dump < Struct.new(:database, :file_path, :skip_tables, :skip_columns)
    include Rake::DSL

    def initialize *args
      super
      self.skip_tables ||= []
      self.skip_columns ||= {}
    end

    def call
      if skip_columns.any?
        SanitizedDatabase.new(skip_columns, file_path).dump do |tables|
          self.skip_tables += tables
          dump
        end
      else
        dump
      end
    end

    private

    def dump
      sh "#{mysqldump} --no-create-db --single-transaction --quick -e #{skip_table_options} #{database.to_mysql_options} #{database.name} | #{pipe} > #{file_path}"
    end

    private

    def mysqldump
      cmd = `which mysqldump`.strip
      raise RuntimeError, "Cannot find mysqldump." if cmd.blank?
      cmd
    end

    def pipe
      file_path =~ /\.gz$/ ? "gzip -9f" : "cat"
    end

    def skip_table_options
      skip_tables.map do |table|
        "--ignore-table=#{database.name}.#{table}"
      end.join(" ")
    end

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
end


