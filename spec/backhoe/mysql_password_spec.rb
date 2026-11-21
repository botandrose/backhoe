require "backhoe"
require "support/database"
require "yaml"
require "tempfile"
require "zlib"

RSpec.describe "MySQL credentials" do
  let(:base) { YAML.load_file("spec/support/database.yml")["test"] }
  let(:admin) { Database.new(base.merge("username" => ENV.fetch("BACKHOE_TEST_MYSQL_USER", base["username"]))) }
  let(:password) { %(s3cret #pw "q" 'q' \\b) }
  let(:config) { base.merge("username" => "backhoe_pw", "password" => password) }
  let(:path) { Tempfile.new(["db", ".sql.gz"]).path }

  around do |example|
    admin.create_db
    admin.load_schema
    connection = ActiveRecord::Base.connection
    admin.execute "DROP USER IF EXISTS 'backhoe_pw'@'localhost'"
    admin.execute "CREATE USER 'backhoe_pw'@'localhost' IDENTIFIED BY #{connection.quote(password)}"
    admin.execute "GRANT ALL ON `#{base["database"]}`.* TO 'backhoe_pw'@'localhost'"
    admin.execute "GRANT PROCESS ON *.* TO 'backhoe_pw'@'localhost'"
    example.run
  ensure
    admin.execute "DROP USER IF EXISTS 'backhoe_pw'@'localhost'"
    admin.destroy_db
  end

  def without_password = satisfy("not include the password") { |output| !output.include?(password) && !output.include?("s3cret") }

  it "dumps with the password without putting it on a command line or in the output" do
    expect { Backhoe::Dump.new(Backhoe::Database.new(config), path).call }
      .to output(without_password).to_stderr_from_any_process
      .and output(without_password).to_stdout_from_any_process

    expect(Zlib.gunzip(File.binread(path))).to include("CREATE TABLE `users`")
  end

  it "loads with the password without putting it on a command line or in the output" do
    Backhoe::Dump.new(Backhoe::Database.new(config), path).call
    admin.execute "DROP TABLE posts"

    expect { Backhoe::Load.new(Backhoe::Database.new(config), path, true).call }
      .to output(without_password).to_stderr_from_any_process
      .and output(without_password).to_stdout_from_any_process

    expect(admin.execute("SHOW TABLES").to_a.flatten).to include("posts", "users")
  end

  it "fails with the wrong password, so the password really is what authenticates" do
    expect {
      Backhoe::Dump.new(Backhoe::Database.new(config.merge("password" => "wrong")), path).call
    }.to raise_error(RuntimeError).and output.to_stderr_from_any_process
  end
end
