require "webrick"

class FakeServer < Struct.new(:path, :port)
  def reset
    FileUtils.rm_rf path
    FileUtils.mkdir_p path
  end

  def start
    @server = WEBrick::HTTPServer.new(Port: port || 0)
    @server.mount_proc "/" do |request, response|
      file = request.body
      upload_file_path = File.join(path, request.path)
      File.open(upload_file_path, "wb") do |f|
        f.write(file)
      end

      response.status = 200
      response.content_type = "text/plain"
      response.body = "File uploaded successfully"
    end

    @thread = Thread.new { @server.start }
    self.port = @server.config[:Port]

    trap("INT") { stop }
  end

  def stop
    @server.shutdown
    @thread.join
  end
end
