class Database < Struct.new(:config)
  def create_db
    ActiveRecord::Base.establish_connection(config.merge(database: nil))
    ActiveRecord::Base.connection.recreate_database(config["database"])
    ActiveRecord::Base.establish_connection(config)
  end

  def load_schema
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
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

  def destroy_db
    ActiveRecord::Base.connection.drop_database(config["database"])
  end

  def load_file path
    create_db
    File.read(path).split(/;$/).each do |line|
      execute line
    end
  end

  def execute *args
    ActiveRecord::Base.connection.execute *args
  end

  def schema
    schema_dumper = ActiveRecord::Base.connection.create_schema_dumper({})
    schema = StringIO.new
    schema_dumper.send(:tables, schema)
    schema.rewind
    schema.read
  end
end

