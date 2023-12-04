require "test_helper"
require "capybara"

Capybara.server = :webrick

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: ENV.fetch("SELENIUM_BROWSER", :headless_chrome).to_sym, screen_size: [1400, 1400]

  def tab_until_focused(*arguments, **options, &block)
    using_wait_time false do
      send_keys(:tab) until page.has_selector?(*arguments, **options, focused: true, &block)
    end
  end
end
