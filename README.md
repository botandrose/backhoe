# Backhoe
[![CI Status](https://github.com/botandrose/backhoe/workflows/CI/badge.svg?branch=master)](https://github.com/botandrose/backhoe/actions?query=workflow%3ACI+branch%3Amaster)

Dump and load current ActiveRecord database to and from a file.

## Usage

```ruby
# Dump
Backhoe.dump "data.sql" # dumps db to db/data.sql
Backhoe.dump "data.sql.gz" # => can also dump a gzipped sql file
Backhoe.dump "data.sql", skip_tables: [:comments], skip_columns: { users: [:password] } # can skip whole tables or just specific columns

# Load
Backhoe.load "data.sql" # loads db from db/data.sql
Backhoe.load "data.sql.gz" # => can also load a gzipped sql file
Backhoe.load "data.sql", drop_and_create: true # injects DROP and CREATE statements into the SQL invocation

# Backup db to S3
Backhoe.backup "bucket-name/folder", access_key: "abc123", secret_key: "def456" # => must specify AWS creds
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/botandrose/backhoe.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
