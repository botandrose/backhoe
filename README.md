# Backhoe
[![CI Status](https://github.com/botandrose/backhoe/workflows/CI/badge.svg?branch=master)](https://github.com/botandrose/backhoe/actions?query=workflow%3ACI+branch%3Amaster)

Dump and load current ActiveRecord database to and from a file.

## Usage

```ruby
# Dump and load db
Backhoe.dump # => dumps db to db/data.sql
Backhoe.load # => loads db from db/data.sql
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/botandrose/backhoe.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
