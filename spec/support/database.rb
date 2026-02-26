require "fileutils"

class Database < Struct.new(:config)
  def create_db
    if sqlite?
      FileUtils.mkdir_p(File.dirname(config["database"]))
      FileUtils.rm_f(config["database"])
      ActiveRecord::Base.establish_connection(config)
    else
      ActiveRecord::Base.establish_connection(config.merge(database: nil))
      ActiveRecord::Base.connection.recreate_database(config["database"])
      ActiveRecord::Base.establish_connection(config)
    end
  end

  def load_schema &block
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        if block_given?
          instance_eval &block
        else
          create_table :users do |t|
            t.integer :name
            t.string :email
            t.string :passhash
          end

          create_table :posts do |t|
            t.integer :user_id
            t.text :body
          end
        end
      end
    end
  end

  def destroy_db
    if sqlite?
      FileUtils.rm_f(config["database"])
    elsif postgresql?
      system "dropdb -f #{name}"
    else
      ActiveRecord::Base.connection.drop_database(config["database"])
    end
  end

  def load_file path
    if sqlite?
      FileUtils.cp(path, config["database"])
      ActiveRecord::Base.connection.reconnect!
    else
      create_db
      if postgresql?
        execute File.read(path)
      else
        File.read(path).split(/;$/).each do |line|
          execute line
        end
      end
    end
  end

  def execute *args
    ActiveRecord::Base.connection.execute *args
  end

  def schema
    schema = StringIO.new
    schema_dumper.send(:tables, schema)
    schema.rewind
    schema.read.strip
  end

  def schema_dumper
    ActiveRecord::Base.connection.reconnect!
    ActiveRecord::Base.connection.create_schema_dumper({})
  end

  def postgresql?
    config["adapter"] == "postgresql"
  end

  def sqlite?
    config["adapter"] == "sqlite3"
  end

  def name
    config["database"]
  end
end

