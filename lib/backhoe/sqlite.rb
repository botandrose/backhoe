require "backhoe/base"
require "fileutils"

module Backhoe
  class Sqlite3 < Base
    def dump **_
      FileUtils.cp database, file_path
    end

    def load
      FileUtils.cp file_path, database
    end
  end
end

