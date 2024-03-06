require "application_system_test_case"

class ValidationsTest < ApplicationSystemTestCase
  test "validates fields in the browser through ActiveModel-generated HTML attributes" do
    visit new_message_path

    within_fieldset "Validate" do
      fill_in "Subject", with: ""
      fill_in "Content", with: "?" * 281
      send_keys :tab

      assert_field "Content", with: "?" * 280
      assert_field "Status", valid: false, validation_message: "Please select an item in the list."
      assert_field "Subject", valid: false, validation_message: "can't be blank"
      assert_text "can't be blank"
    end
  end

  test "validates fields on input and blur by default" do
    visit new_message_path

    within_fieldset "Validate" do
      tab_until_focused :field, "Subject"

      assert_field "Subject", focused: true, valid: false

      send_keys :tab

      assert_field "Subject", focused: false, valid: false, described_by: "can't be blank"

      send_keys [:shift, :tab]

      assert_field "Subject", focused: true, valid: false, described_by: "can't be blank"

      send_keys "valid"

      assert_field "Subject", focused: true, valid: true

      send_keys :tab

      assert_field "Subject", focused: false, valid: true
    end
  end

  test "configures which events to validate after" do
    visit new_message_path(validateOn: ["blur"])

    within_fieldset "Validate" do
      tab_until_focused :field, "Subject"

      assert_field "Subject", focused: true, valid: false

      send_keys :tab

      assert_field "Subject", focused: false, valid: false, described_by: "can't be blank"

      send_keys [:shift, :tab]

      assert_field "Subject", focused: true, valid: false, described_by: "can't be blank"

      send_keys "valid"

      assert_field "Subject", focused: true, valid: false, described_by: "can't be blank"

      send_keys :tab

      assert_field "Subject", focused: false, valid: true
    end
  end

  test "ignores disabled fields on the client" do
    visit new_message_path(disableSubmitWhenInvalid: false)

    within_fieldset "Validate" do
      click_on "Create Message"

      assert_no_field "Disabled", valid: false, disabled: true
      assert_field "Status", valid: false, focused: true, validation_message: "can't be blank"
    end
  end

  test "validates fields on the server" do
    visit new_message_path(disableSubmitWhenInvalid: true)

    within_fieldset "Validate" do
      select "published", from: "Status"
      fill_in "Subject", with: "forbidden"
      fill_in "Content", with: "not empty"
      click_on "Create Message"

      assert_field "Disabled", valid: true, disabled: true
      assert_field "Subject", valid: false, validation_message: "is reserved", focused: true
      assert_button "Create Message", disabled: true
      assert_button "Skip Validations", disabled: false
    end
  end

  test "presents custom Active Model validations from the server" do
    visit new_message_path(disableSubmitWhenInvalid: false)

    within_fieldset "Validate" do
      fill_in "Subject", with: "invalid"
      click_on "Skip Validations"

      assert_field "Subject", valid: false, validation_message: "cannot equal invalid", described_by: "cannot equal invalid"
      assert_text "cannot equal invalid"
    end
  end

  test "focuses first invalid field when connected with multiple invalid fields" do
    visit new_message_path(disableSubmitWhenInvalid: false)

    within_fieldset "Validate" do
      click_on "Create Message"

      assert_field "Disabled", valid: true, disabled: true
      assert_field "Status", valid: false, focused: true
      assert_field "Subject", valid: false, focused: false
      assert_field "Content", valid: false, focused: false
    end
  end

  test "disables submit button when server-rendered response is invalid" do
    visit new_message_path(disableSubmitWhenInvalid: true)

    within_fieldset "Validate" do
      click_on "Skip Validations"

      assert_field "Disabled", valid: true, disabled: true
      assert_field "Status", valid: false, focused: true
      assert_field "Subject", valid: false, focused: false
      assert_field "Content", valid: false, focused: false
      assert_button "Create Message", disabled: true
    end
  end

  test "does not focus an invalid field on blur" do
    visit new_message_path

    within_fieldset "Validate" do
      tab_until_focused :field, "Status"
      tab_until_focused :field, "Subject"
      tab_until_focused :field, "Content"

      assert_field "Status", focused: false, valid: false
      assert_field "Subject", focused: false, valid: false
      assert_field "Content", focused: true
    end
  end

  test "disables the submit button when invalid" do
    visit new_message_path(disableSubmitWhenInvalid: true)

    within_fieldset "Validate" do
      assert_button "Create Message", disabled: true
      assert_button "Skip Validations", disabled: false

      tab_until_focused :field, "Content"
      send_keys "valid"

      assert_button "Create Message", disabled: true
      assert_button "Skip Validations", disabled: false
      assert_field "Status", validation_message: "can't be blank"
      assert_field "Subject", validation_message: "can't be blank"

      select("published", from: "Status").then { tab_until_focused :field, "Subject" }
      fill_in("Subject", with: "valid").then { tab_until_focused :field, "Content" }

      assert_button "Create Message", disabled: false
      assert_button "Skip Validations", disabled: false
      assert_no_text "can't be blank"
      assert_no_field validation_message: "Please select an item in the list."
      assert_no_field validation_message: "can't be blank"
    end
  end

  test "clears validation state when submission is valid" do
    visit new_message_path(disableSubmitWhenInvalid: false)

    within_fieldset "Validate" do
      click_on "Create Message"
      assert_field valid: false, count: 3
    end

    assert_no_selector :alert, text: "Message Created."

    within_fieldset "Validate" do
      select "published", from: "Status"
      fill_in "Subject", with: "valid"
      fill_in "Content", with: "valid"

      assert_no_field valid: false, disabled: true
      assert_no_field valid: false

      click_on "Create Message"
    end

    assert_selector :alert, text: "Message Created."
  end

  test "checkbox with single [required] checkbox requires it to be checked" do
    visit new_form_path

    tab_until_focused :field, "Single required checkbox"

    assert_unchecked_field "Single optional checkbox", valid: true
    assert_unchecked_field "Single required checkbox", valid: false do |input|
      input.assert_matches_selector :element, required: true, "aria-required": false
    end

    send_keys :tab

    assert_unchecked_field "Single optional checkbox", valid: true
    assert_unchecked_field "Single required checkbox", valid: false, validation_message: "can't be blank", described_by: "can't be blank"

    check "Single required checkbox"

    assert_unchecked_field "Single optional checkbox", valid: true
    assert_checked_field "Single required checkbox", valid: true
    within_fieldset "Single [required] checkbox" do
      assert_no_text "can't be blank"
    end

    uncheck "Single required checkbox"

    assert_unchecked_field "Single optional checkbox", valid: true
    assert_unchecked_field "Single required checkbox", valid: false, validation_message: "can't be blank", described_by: "can't be blank"

    check "Single required checkbox"

    assert_unchecked_field "Single optional checkbox", valid: true
    assert_checked_field "Single required checkbox", valid: true
    within_fieldset "Single [required] checkbox" do
      assert_no_text "can't be blank"
    end
  end

  test "checkbox with multiple [required] checkbox requires one to be checked" do
    visit new_form_path(checkbox: true)

    within_fieldset "Multiple [required] checkboxes" do
      assert_unchecked_field "Multiple required checkbox", exact: false, valid: false, count: 2 do |input|
        input.assert_matches_selector :element, required: false, "aria-required": "true"
      end

      tab_until_focused :field, "Multiple required checkbox #2"

      assert_unchecked_field "Multiple required checkbox", exact: false, valid: false, validation_message: "can't be blank", described_by: "can't be blank", count: 2
      assert_text "can't be blank", count: 1

      check "Multiple required checkbox #2"

      assert_field "Multiple required checkbox", exact: false, valid: true, count: 2
      assert_checked_field "Multiple required checkbox #2", valid: true
      assert_unchecked_field "Multiple required checkbox #1", valid: true
      assert_no_text "can't be blank"

      check "Multiple required checkbox #1"

      assert_checked_field "Multiple required checkbox #1", valid: true
      assert_checked_field "Multiple required checkbox #2", valid: true
      assert_no_text "can't be blank"

      uncheck "Multiple required checkbox #2"

      assert_field "Multiple required checkbox", exact: false, valid: true, count: 2
      assert_unchecked_field "Multiple required checkbox #2", valid: true
      assert_checked_field "Multiple required checkbox #1", valid: true
      assert_no_text "can't be blank"

      uncheck "Multiple required checkbox #1"

      assert_unchecked_field "Multiple required checkbox", exact: false, valid: false, validation_message: "can't be blank", described_by: "can't be blank", count: 2
      assert_text "can't be blank", count: 1

      check "Multiple required checkbox #2"

      assert_field "Multiple required checkbox", exact: false, valid: true, count: 2
      assert_checked_field "Multiple required checkbox #2", valid: true
      assert_unchecked_field "Multiple required checkbox #1", valid: true
      assert_no_text "can't be blank"

      check "Multiple required checkbox #1"

      assert_checked_field "Multiple required checkbox #1", valid: true
      assert_checked_field "Multiple required checkbox #2", valid: true
      assert_no_text "can't be blank"
    end
  end

  test "observes connection of multiple [required] checkboxes" do
    connected = proc do |input|
      input.assert_matches_selector :element, required: false, "aria-required": "true"
    end

    visit new_form_path(hotwire_enabled: true, checkbox: true)
    click_button "Skip Validations"

    within_fieldset "Multiple [required] checkboxes" do
      assert_unchecked_field "Multiple required checkbox #1", valid: false, &connected
      assert_unchecked_field "Multiple required checkbox #2", valid: false, &connected
      assert_unchecked_field "Multiple required checkbox #3", disabled: true, valid: true, &connected
    end
  end

  test "does not group checkboxes without checkbox: true" do
    visit new_form_path

    within_fieldset "Multiple [required] checkboxes" do
      assert_unchecked_field "Multiple required checkbox", exact: false, valid: false, count: 2 do |input|
        input.assert_matches_selector :element, required: true, "aria-required": false
      end

      check "Multiple required checkbox #1"

      assert_checked_field "Multiple required checkbox #1", valid: true
      assert_unchecked_field "Multiple required checkbox #2", valid: false
    end
  end
end

class NoValidationsTest < ApplicationSystemTestCase
  test "skips validation within <form novalidate>" do
    visit new_message_path

    within_fieldset "Novalidate" do
      fill_in "Subject", with: ""
      send_keys :tab

      assert_no_text "can't be blank"
      assert_button "Create Message", disabled: false
    end
  end

  test "renders server-side errors but does not use Constraint Validation API" do
    visit new_message_path

    within_fieldset "Novalidate" do
      click_on "Create Message"

      assert_no_field "Subject", valid: true, validation_message: ""
    end
  end

  test "renders field-specific validation message templates" do
    visit new_message_path

    within_fieldset "Novalidate" do
      click_on "Create Message"

      assert_selector "p.customized", text: "can't be blank", count: 2
    end
  end
end

class NativeValidationsTest < ApplicationSystemTestCase
  test "does not intercept native validations when missing both the [aria-errormessage] element and the `<template>` element" do
    visit new_message_path skip: true

    within_fieldset "Validate" do
      fill_in "Subject", with: ""
      send_keys :tab

      assert_no_text "can't be blank"
      assert_field "Status", valid: false, validation_message: "Please select an item in the list."
      assert_field "Subject", valid: false, validation_message: "Please fill out this field."
    end
  end
end
