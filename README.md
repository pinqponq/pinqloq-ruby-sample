# pinqloq Ruby Sample

A Sinatra sample application that will demonstrate how to integrate the `pinqloq` Ruby SDK into a backend service.

## Requirements

- Ruby 3.3 or later
- Bundler

## Install

```bash
bundle install
```

## Run

```bash
bundle exec rackup -p 3200
```

Open [http://127.0.0.1:3200](http://127.0.0.1:3200).

The test lab page lets you trigger HTTP scenarios returning 200, 400, 401, 404, or 500 and inspect the raw response.

## Test

```bash
bundle exec rspec
```

## Status

This scaffold has HTTP scenario endpoints and a browser test lab only. `pinqloq` SDK integration — automatic Rack middleware logging, manual events, redaction — is a follow-up step.

## Project standards

Shared conventions are vendored from [pinq-doq](https://github.com/pinqponq/pinqdoq) under `.pinq-doq/` and copied into `.claude/rules/`. See [CLAUDE.md](CLAUDE.md).

## License

MIT
