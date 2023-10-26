source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in constraint_validations.gemspec.
gemspec

# To use a debugger
# gem 'byebug', group: [:development, :test]

rails_version = ENV.fetch("RAILS_VERSION", "6.1")

if rails_version == "main"
  rails_constraint = { github: "rails/rails" }
else
  rails_constraint = "~> #{rails_version}.0"
end

gem "rails", rails_constraint
gem "sprockets-rails"

group :test do
  gem "capybara", ">= 3.26", require: "capybara/minitest"
  gem "capybara_accessible_selectors", github: "citizensadvice/capybara_accessible_selectors", tag: "v0.4.1"
  gem "rexml"
  gem "selenium-webdriver"
  gem "webrick"
end
