source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in constraint_validations.gemspec.
gemspec

# To use a debugger
# gem 'byebug', group: [:development, :test]

gem "rails", github: "rails/rails"

group :test do
  gem "capybara", '>= 3.26'
  gem "capybara_accessible_selectors", github: "citizensadvice/capybara_accessible_selectors", tag: "v0.4.1"
  gem "rexml"
  gem "selenium-webdriver"
  gem "webdrivers"
  gem "webrick"
end
