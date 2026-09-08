# pinqloq Ruby Sample

A Sinatra sample application demonstrating how to integrate the `pinqloq` Ruby SDK into a backend service.

It includes a browser-based test lab for automatic HTTP logging, manual structured events, and redaction. The application generates synthetic data only. Your Pinqloq secret key stays on the server and is never exposed to browser code.

## Requirements

- Ruby 3.3 or later
- Bundler
- A Pinqloq account
- A Pinqloq project and secret key
- One collection for automatic HTTP logs
- One collection for manual events

## Dashboard setup

1. Sign in to the [Pinqloq dashboard](https://pinqloq.pinqponq.io).
2. Create a project and copy its secret key.
3. Create two collections. Suggested names are `pinqloq_ruby_test_http` and `pinqloq_ruby_test_manual`.
4. View delivered logs in the [Pinqloq log panel](https://pinqloq-panel.pinqponq.io).

Never place the secret key in frontend code, a mobile application, source control, or any file served to users.

## Install

```bash
bundle install
```

Copy `.env.example` to `.env` and fill in your secret key and collection names:

```bash
cp .env.example .env
```

```env
PINQLOQ_SECRET_KEY=your-project-secret-key
PINQLOQ_HTTP_COLLECTION=pinqloq_ruby_test_http
PINQLOQ_MANUAL_COLLECTION=pinqloq_ruby_test_manual
```

The `.env` file is ignored by Git and must never be committed. Without it, the app still runs — the pinqloq middleware and manual/redaction routes are simply disabled (`/api/config` reports `configured: false`).

## Install and import pinqloq

The `pinqloq` gem is not yet published to RubyGems. This sample pulls it straight from its source repository with Bundler's git `glob` option, which locates the gemspec inside `pinqloq-backend`'s `sdk/pinqloq-ruby` subdirectory:

```ruby
gem "pinqloq",
    git: "https://github.com/pinqponq/pinqloq-backend.git",
    ref: "<commit sha on main>",
    glob: "sdk/pinqloq-ruby/*.gemspec"
```

A plain `bundle install` resolves this directly — no vendoring, submodule, or local tarball needed. Bump `ref` to a newer `main` commit and run `bundle install` again to pick up SDK updates.

Once the SDK is published, any Ruby backend will be able to install it directly:

```bash
gem install pinqloq
```

## Run

```bash
bundle exec rackup -p 3200
```

Open [http://127.0.0.1:3200](http://127.0.0.1:3200).

The browser UI provides:

1. HTTP scenarios returning 200, 400, 401, 404, or 500 — captured automatically by `Pinqloq::Rack::RequestLogging`.
2. Manual events at Debug, Information, Warning, Error, and Fatal levels via `logger.enqueue`.
3. Redaction tests — one endpoint redacts only the `taxNumber` field (`password` is redacted unconditionally by the SDK's built-in floor), the other redacts everything on the endpoint.

## Test

```bash
bundle exec rspec
```

Automated tests never send data to the live service: `PINQLOQ_SECRET_KEY` is left unset while testing, which disables the middleware and the manual/redaction routes (asserted to return `503`) without touching the network.

## Project standards

Shared conventions are vendored from [pinq-doq](https://github.com/pinqponq/pinqdoq) under `.pinq-doq/` and copied into `.claude/rules/`. See [CLAUDE.md](CLAUDE.md).

## License

MIT
