require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"

  gem "rails"
  gem "propshaft"
  gem "puma"
  gem "sqlite3"
  gem "turbo-rails"
  gem "stimulus-rails"
  gem "constraint_validations", require: false, github: "seanpdoyle/constraint_validations"

  gem "capybara"
  gem "cuprite", require: "capybara/cuprite"
end

ENV["DATABASE_URL"] = "sqlite3::memory:"
ENV["RAILS_ENV"] = "test"

require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_view/railtie"
# require "action_mailer/railtie"
# require "active_job/railtie"
require "action_cable/engine"
# require "action_mailbox/engine"
# require "action_text/engine"
require "rails/test_unit/railtie"

class App < Rails::Application
  config.load_defaults Rails::VERSION::STRING.to_f

  config.root = __dir__
  config.hosts << "example.org"
  config.eager_load = false
  config.session_store :cookie_store, key: "cookie_store_key"
  config.secret_key_base = "secret_key_base"
  config.consider_all_requests_local = true
  config.action_cable.cable = {"adapter" => "async"}
  config.turbo.draw_routes = false
  config.action_view.field_error_proc = proc { |html| html }
  config.before_configuration { require "constraint_validations" }

  Rails.logger = config.logger = Logger.new($stdout)

  routes.append do
    resources :articles, only: [:new, :create, :show]
  end
end

Rails.application.initialize!

ActiveRecord::Schema.define do
  create_table :articles, force: true do |t|
    t.text :json, null: false, default: "{}"
  end
end

class Article < ActiveRecord::Base
  store :json, coder: JSON, accessors: [
    :name,
    :body
  ]

  validates :name, presence: true
  validates :body, presence: true
end

class ArticlesController < ActionController::Base
  include Rails.application.routes.url_helpers

  class_attribute :template, default: DATA.read

  def new
    @article = Article.new

    render inline: template, formats: :html
  end

  def create
    @article = Article.new(params.require(:article).permit!)

    if @article.save
      redirect_to new_article_path
    else
      render status: :unprocessable_entity, formats: :html, inline: template
    end
  end
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, using: :chrome, screen_size: [1400, 1400], options: {js_errors: true}
end

Capybara.configure do |config|
  config.server = :puma, {Silent: true}
  config.default_normalize_ws = true
end

require "rails/test_help"

class SystemTest < ApplicationSystemTestCase
  test "reproduces bug" do
    visit new_article_path

    click_button "Create Article"
    fill_in "Name", validation_message: "can't be blank", with: "A name"
    fill_in "Body", validation_message: "can't be blank", with: "A body"
    click_button "Create Article"

    assert_link "A name"
  end
end

__END__
<!DOCTYPE html>
<html>
  <head>
    <%= csrf_meta_tags %>

    <script type="importmap">
      {
        "imports": {
          "@hotwired/turbo-rails": "<%= asset_path("turbo.js") %>",
          "@hotwired/stimulus": "<%= asset_path("stimulus.js") %>",
          "@seanpdoyle/constraint_validations": "<%= asset_path("constraint_validations.es.js") %>"
        }
      }
    </script>

    <script type="module">
      import "@hotwired/turbo-rails"
      import { Application, Controller } from "@hotwired/stimulus"
      import ConstraintValidations from "@seanpdoyle/constraint_validations"

      const application = Application.start()
      application.register("constraint-validations", class extends Controller {
        static values = { options: Object }

        connect() {
          this.validations = new ConstraintValidations(this.element, this.optionsValue)
          this.validations.connect()
        }

        disconnect() {
          this.validations.disconnect()
        }
      })
    </script>
  </head>

  <body>
    <% Article.all.each do |article| %>
      <%= link_to article.name, article %>
    <% end %>

    <%= form_with model: @article, data: {
          controller: "constraint-validations",
          constraint_validations_options_value: {}
        } do |form| %>
      <%= form.validation_message_template do |validation_messages, tag| %>
        <%= tag.span validation_messages.to_sentence %>
      <% end %>

      <%= form.label :name %>
      <%= form.text_field :name %>
      <%= form.validation_message :name %>

      <%= form.label :body %>
      <%= form.text_area :body %>
      <%= form.validation_message :body %>

      <%= form.button %>
    <% end %>
  </body>
</html>
