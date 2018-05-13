require "backhoe/base"

module Backhoe
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

