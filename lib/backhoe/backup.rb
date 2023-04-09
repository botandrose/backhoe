module Backhoe
  class Backup < Struct.new(:s3_path, :access_key, :secret_key)
    def call
      Backhoe.dump path
      Kernel.system "#{creds} aws s3 mv #{path} s3://#{s3_path}/#{filename}".strip
    end

    private

    def creds
      if access_key && secret_key
        "AWS_ACCESS_KEY_ID=#{access_key} AWS_SECRET_ACCESS_KEY=#{secret_key}"
      end
    end

    def path
      "/tmp/#{filename}"
    end

    def filename
      @filename ||= begin
        require "time"
        "#{Time.now.utc.iso8601}.sql.gz"
      end
    end
  end
end

