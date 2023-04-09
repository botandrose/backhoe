# Backhoe
[![CI Status](https://github.com/botandrose/backhoe/workflows/CI/badge.svg?branch=master)](https://github.com/botandrose/backhoe/actions?query=workflow%3ACI+branch%3Amaster)

Dump and load current ActiveRecord database to and from a file.

## Usage

```ruby
# Dump
Backhoe.dump # dumps db to db/data.sql
Backhoe.dump file_path: "/tmp/database.sql" # => dumps db to /tmp/database.sql
Backhoe.dump skip_tables: [:comments], skip_columns: { users: [:password] } # can skip whole tables or just specific columns

# Load
Backhoe.load # loads db from db/data.sql
Backhoe.load file_path: "/tmp/database.sql" # => loads db from /tmp/database.sql
Backhoe.load drop_and_create: true # injects DROP and CREATE statements into the SQL invocation

# Backup db to S3
Backhoe.backup "bucket-name/folder" # => dumps db to e.g. s3://bucket-name/folder/2023-04-09T16:41:26Z.sql.gz via AWS CLI, assuming that credentials are already configured.
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/botandrose/backhoe.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
