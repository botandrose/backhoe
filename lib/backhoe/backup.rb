require "net/http"
require "openssl"
require "base64"

module Backhoe
  class Backup < Struct.new(:s3_path, :access_key, :secret_key)
    def call
      @time = Time.now

      Backhoe.dump path

      uri = URI("https://s3-us-west-2.amazonaws.com/#{s3_path}/#{filename}")

      req = Net::HTTP::Put.new(uri, {
        "Content-Length": File.size(path).to_s,
        "Content-Type": content_type,
        "Date": date,
        "Authorization": "AWS #{access_key}:#{signature}",
        "x-amz-storage-class": "STANDARD",
        "x-amz-acl": "private",
      })
      req.body_stream = File.open(path)
      Net::HTTP.start(uri.hostname) { |http| http.request(req) }
    end

    private

    def signature
      digester = OpenSSL::Digest::SHA1.new
      digest = OpenSSL::HMAC.digest(digester, secret_key, key)
      Base64.strict_encode64(digest)
    end

    def key
      [
        "PUT",
        "",
        content_type,
        date,
        acl,
        storage_type,
        full_s3_path,
      ].join("\n")
    end

    def content_type
      "application/gzip"
    end

    def date
      @time.rfc2822
    end

    def acl
      "x-amz-acl:private"
    end

    def storage_type
      "x-amz-storage-class:STANDARD"
    end

    def full_s3_path
      "/#{s3_path}/#{filename}"
    end

    def path
      "/tmp/#{filename}"
    end

    def filename
      "#{@time.utc.iso8601}.sql.gz"
    end
  end
end

