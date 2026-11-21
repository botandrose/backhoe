require "rake"
require "shellwords"

module Backhoe
  class Dump < Struct.new(:database, :path, :skip_tables, :skip_columns, :scrub_columns)
    include Rake::DSL

    def initialize *args
      super
      self.skip_tables ||= []
      self.skip_columns ||= {}
      self.scrub_columns ||= {}
    end

    def call
      if skip_tables.any? || skip_columns.any? || scrub_columns.any?
        raise NotImplementedError if database.postgresql?
      end
      if skip_columns.any? || scrub_columns.any?
        SanitizedDatabase.new(skip_columns, scrub_columns).dump do |tables, trailer|
          dump skip_tables + tables, trailer
        end
      else
        dump skip_tables
      end
    end

    private

    def dump skipped, trailer = nil
      if database.mysql?
        trailer = "; printf '\\n%s' #{Shellwords.escape(trailer)}" if trailer
        bash_sh "{ #{mysqldump} --no-create-db --single-transaction --quick -e #{skip_table_options(skipped)} #{database.to_mysql_options} #{database.name}#{trailer}; } | #{pipe} #{target}"
      elsif database.postgresql?
        bash_sh "#{pg_dump} --column-inserts #{database.name} | #{pipe} #{target}"
      elsif database.sqlite?
        bash_sh "cat #{database.path} | #{pipe} #{target}"
      else
        raise "don't know how to dump #{database.adapter}"
      end
    end

    def bash_sh(command)
      sh <<~EOS
        /bin/bash -xeu <<'BASH'
        set -o pipefail && #{command}
        BASH
      EOS
    end

    private

    def target
      if path =~ /^https?:\/\//
        "| curl -X PUT -H 'Content-Type: application/octet-stream' --data-binary @- '#{path}'"
      else
        "> #{path}"
      end
    end

    def mysqldump
      cmd = `which mysqldump`.strip
      raise RuntimeError, "Cannot find mysqldump." if cmd.blank?
      cmd
    end

    def pg_dump
      cmd = `which pg_dump`.strip
      raise RuntimeError, "Cannot find pg_dump." if cmd.blank?
      cmd
    end

    def pipe
      path =~ /\.gz\b/ ? "gzip -9f" : "cat"
    end

    def skip_table_options skipped
      skipped.map do |table|
        "--ignore-table=#{database.name}.#{table}"
      end.join(" ")
    end

    # Copies each table aside, strips the copy, dumps it in place of the original, and
    # renames it back at the end of the dump.
    class SanitizedDatabase
      def initialize skip_columns, scrub_columns
        @skip_columns = skip_columns.to_h { |table, columns| [table.to_s, columns] }
        @scrub_columns = scrub_columns.to_h { |table, columns| [table.to_s, columns] }
      end

      def dump
        tables.each { |table| copy table }
        yield tables, tables.map { |table| "RENAME TABLE `sanitized_#{table}` TO `#{table}`;" }.join("\n")
      ensure
        tables.each { |table| sql "DROP TABLE IF EXISTS `sanitized_#{table}`" }
      end

      private

      def tables
        (@skip_columns.keys + @scrub_columns.keys).uniq
      end

      def copy table
        copy = "sanitized_#{table}"
        sql "DROP TABLE IF EXISTS `#{copy}`"
        sql "CREATE TABLE `#{copy}` LIKE `#{table}`"
        sql "INSERT INTO `#{copy}` SELECT * FROM `#{table}`"

        scrubs = @scrub_columns.fetch(table, {})
        if scrubs.any?
          sets = scrubs.map { |column, expression| "`#{column}` = #{expression.nil? ? "NULL" : expression}" }
          sql "UPDATE `#{copy}` SET #{sets.join(", ")}"
        end

        skips = @skip_columns.fetch(table, [])
        if skips.any?
          sql "ALTER TABLE `#{copy}` #{skips.map { |column| "DROP `#{column}`" }.join(", ")}"
        end
      end

      def sql query
        ActiveRecord::Base.connection.execute query
      end
    end
  end
end


