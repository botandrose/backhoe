require "rake"

module Backhoe
  class Base < Struct.new(:config, :file_path)
    include Rake::DSL

    private

    def database
      config["database"]
    end
  end
end

