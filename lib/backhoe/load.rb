require "rake"

module Backhoe
  class Load < Struct.new(:database, :file_path, :drop_and_create)
    include Rake::DSL

    def call
      sh command
    end

    private

    def command
      cmd = "#{cat} #{file_path} | "
      cmd += if drop_and_create
        "#{pipe} | #{mysql} #{database.to_mysql_options}"
      else
        "#{mysql} #{database.to_mysql_options} #{database.name}"
      end
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
  end
end

