source "https://rubygems.org"

ruby "3.3.12"

gem "sinatra", "~> 4.0"
gem "puma", "~> 6.4"
gem "rackup", "~> 2.1"
gem "dotenv", "~> 3.1"
gem "pinqloq",
    git: "https://github.com/pinqponq/pinqloq-backend.git",
    ref: "2302191f1d2af41c5566dc24fe310b4c8a03e64f",
    glob: "sdk/pinqloq-ruby/*.gemspec"

group :test do
  gem "rspec", "~> 3.13"
  gem "rack-test", "~> 2.1"
end
