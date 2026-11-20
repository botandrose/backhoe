require "backhoe/version"
require "backhoe/dump"
require "backhoe/load"
require "backhoe/database"
require "active_record"

module Backhoe
  class << self
    def dump path, skip_tables: [], skip_columns: {}
      Dump.new(Database.new, path, skip_tables, skip_columns).call
    end

    def load path, drop_and_create: false
      Load.new(Database.new, path, drop_and_create).call
    end
  end
end

