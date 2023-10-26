# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
require "rails/test_help"

class ConstraintValidations::TestCase < ActiveSupport::TestCase
  include Capybara::Minitest::Assertions

  attr_reader :rendered

  def render(*arguments, renderer: ApplicationController.renderer, **options, &block)
    @rendered = renderer.render(*arguments, **options, &block)
  end

  def document_root_element
    Nokogiri::HTML(@rendered).tap { |element| raise "Don't forget to call `render`" if element.nil? }
  end

  def page
    Capybara.string(document_root_element)
  end

  def assert_element(...)
    assert_selector(:element, ...)
  end

  def assert_no_element(...)
    assert_no_selector(:element, ...)
  end
end
