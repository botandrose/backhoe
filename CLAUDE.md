# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Backhoe is a Ruby gem for dumping and loading ActiveRecord database contents to/from files. Supports MySQL, PostgreSQL, and SQLite adapters with gzip compression and remote HTTP PUT.

## Commands

```bash
bundle exec rake          # Run full test suite (RSpec)
bundle exec rspec         # Run all specs
bundle exec rspec spec/backhoe/dump_spec.rb  # Run a single spec file
bundle exec rspec spec/backhoe/dump_spec.rb:15  # Run a single example by line
```

Tests require running MySQL and PostgreSQL services. Test database config is in `spec/support/database.yml`.

## Architecture

The gem has two public methods: `Backhoe.dump(path, **options)` and `Backhoe.load(path, **options)`.

Three core classes implement the functionality:

- **Backhoe::Database** (`lib/backhoe/database.rb`) - Reads ActiveRecord connection config, detects the adapter type (`mysql?`, `postgresql?`, `sqlite?`), and builds CLI options for database tools.
- **Backhoe::Dump** (`lib/backhoe/dump.rb`) - Runs `mysqldump`, `pg_dump`, or file copy depending on adapter. Handles gzip, table skipping, column sanitization (via temp tables), and HTTP PUT for remote storage. Uses `Rake::DSL#sh` for shell commands.
- **Backhoe::Load** (`lib/backhoe/load.rb`) - Runs `mysql`, `psql`, or file copy to restore. Supports gzip decompression and optional drop/create database.

Shell commands use `set -o pipefail` in bash to catch piping errors.

## Testing

The test suite uses Appraisals to test against ActiveRecord 7.0, 7.1, and 7.2. CI runs on GitHub Actions across Ruby 3.1–3.3 with that matrix.

Test support files in `spec/support/` include a `Database` helper class for creating/destroying test databases and fixture SQL files for both MySQL and PostgreSQL.
