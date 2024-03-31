require "rake"

module Backhoe
  class Load < Struct.new(:database, :file_path, :drop_and_create)
    include Rake::DSL

    def call
      case database.adapter
      when "mysql2"
        sh mysql_command
      when "postgresql"
        sh psql_command
      else
        raise "don't know how to load #{database.adapter}"
      end
    end

    private

    def mysql_command
      cmd = "#{cat} #{file_path} | "
      cmd += if drop_and_create
        "#{pipe} | #{mysql} #{database.to_mysql_options}"
      else
        "#{mysql} #{database.to_mysql_options} #{database.name}"
      end
    end

    def psql_command
      cmd = "#{cat} #{file_path} | "
      if drop_and_create
        cmd = "dropdb -f #{database.name}; createdb #{database.name}; #{cmd}"
      end
      cmd += "#{psql} -P pager=off -q -d#{database.name}"
      cmd
    end

    def cat
      file_path =~ /\.gz$/ ? "zcat" : "cat"
    end

    def pipe
      if drop_and_create
        "(echo -n '#{<<~SQL}' && cat)"
          DROP DATABASE IF EXISTS #{database.name};
          CREATE DATABASE #{database.name};
          USE #{database.name};
        SQL
      else
        "cat"
      end
    end

    def mysql
      cmd = `which mysql`.strip
      raise RuntimeError, "Cannot find mysql." if cmd.blank?
      cmd
    end

    def psql
      cmd = `which psql`.strip
      raise RuntimeError, "Cannot find psql." if cmd.blank?
      cmd
    end
  end
end

