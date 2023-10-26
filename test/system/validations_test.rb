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

  test "validates fields on the server" do
    visit new_message_path

    within_fieldset "Validate" do
      select "published", from: "Status"
      fill_in "Subject", with: "forbidden"
      fill_in "Content", with: "not empty"
      click_on "Create Message"

      assert_field "Subject", valid: false, validation_message: "is reserved"
      assert_button "Create Message", disabled: false
    end
  end

  test "focuses first invalid field on submission" do
    visit new_message_path

    within_fieldset "Validate" do
      click_on "Create Message"

      assert_field "Status", valid: false, focused: true
      assert_field "Subject", valid: false, focused: false
      assert_field "Content", valid: false, focused: false
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
    visit new_message_path

    within_fieldset "Validate" do
      assert_button "Create Message", disabled: false

      tab_until_focused :field, "Content"
      send_keys "valid"

      assert_button "Create Message", disabled: true
      assert_field "Status", validation_message: "can't be blank"
      assert_field "Subject", validation_message: "can't be blank"

      select("published", from: "Status").then { tab_until_focused :field, "Subject" }
      fill_in("Subject", with: "valid").then { tab_until_focused :field, "Content" }

      assert_button "Create Message", disabled: false
      assert_no_text "can't be blank"
      assert_no_field validation_message: "Please select an item in the list."
      assert_no_field validation_message: "can't be blank"
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
