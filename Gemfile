source "https://rubygems.org"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem "jbuilder", "~> 2.5"
gem "multipart-post", "~> 2.0"
gem "puma", "~> 3.7"
gem "rails", "~> 5.1.1"
gem "sidekiq", "~> 5.0"
gem "sqlite3"
gem "sys-filesystem", "~> 1.1.7"
gem "terminal-table", "~> 1.8"
gem "thor", "~> 0.19"

group :development, :test do
  gem "byebug", platforms: %i[mri mingw x64_mingw]
end

group :development do
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
end

group :test do
  gem "brakeman"
  gem "factory_girl_rails"
  gem "rspec-rails"
  gem "rubocop"
  gem "rubocop-rspec"
  gem "shoulda"
  gem "simplecov", require: false
end

gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]
