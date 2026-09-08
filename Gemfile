source "https://rubygems.org"

ruby "3.3.12"

gem "sinatra", "~> 4.0"
gem "puma", "~> 6.4"
gem "rackup", "~> 2.1"
gem "dotenv", "~> 3.1"
gem "pinqloq",
    git: "https://github.com/pinqponq/pinqloq-backend.git",
    ref: "ce9eb27817a1425b739b4852d18a314a7736addb",
    glob: "sdk/pinqloq-ruby/*.gemspec"

group :test do
  gem "rspec", "~> 3.13"
  gem "rack-test", "~> 2.1"
end
