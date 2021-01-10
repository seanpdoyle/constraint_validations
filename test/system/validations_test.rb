require "application_system_test_case"

class ValidationsTest < ApplicationSystemTestCase
  test "validates fields in the browser through ActiveModel-generated HTML attributes" do
    visit new_message_path

    within_section "Validate" do
      fill_in "Subject", with: ""
      fill_in "Content", with: "?" * 281
      send_keys :tab

      assert_field "Content", with: "?" * 280
      assert_field "Subject", valid: false, validation_message: "can't be blank"
      assert_text "can't be blank"
    end
  end

  test "validates fields on the server" do
    visit new_message_path

    within_section "Validate" do
      fill_in "Subject", with: "forbidden"
      click_on "Create Message"

      assert_field "Subject", valid: false, validation_message: "is reserved"
      assert_button "Create Message", disabled: false
    end
  end

  test "disables the submit button when invalid" do
    visit new_message_path

    within_section "Validate" do
      assert_button "Create Message", disabled: false

      fill_in("Subject", with: "").then { send_keys :tab }

      assert_button "Create Message", disabled: true
      assert_text "can't be blank"

      fill_in("Subject", with: "valid").then { send_keys :tab }

      assert_button "Create Message", disabled: false
      assert_no_text "can't be blank"
    end
  end
end

class NoValidationsTest < ApplicationSystemTestCase
  test "skips validation within <form novalidate>" do
    visit new_message_path

    within_section "Novalidate" do
      fill_in "Subject", with: ""
      send_keys :tab

      assert_no_text "can't be blank"
      assert_button "Create Message", disabled: false
    end
  end

  test "renders server-side errors but does not use Constraint Validation API" do
    visit new_message_path

    within_section "Novalidate" do
      click_on "Create Message"

      assert_no_field "Subject", valid: true, validation_message: ""
    end
  end

  test "renders field-specific validation message templates" do
    visit new_message_path

    within_section "Novalidate" do
      click_on "Create Message"

      assert_selector "p.customized", text: "can't be blank"
    end
  end
end
