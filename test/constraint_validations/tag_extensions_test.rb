require "test_helper"

class ConstraintValidations::AriaTagExtensionsTest < ConstraintValidations::TestCase
  setup { @object_name = "aria_tag_extensions_test_message" }

  Message = Class.new do
    include ActiveModel::Model

    attr_accessor :content, :published

    validates :content, presence: true, length: {maximum: 100}
    validates :published, presence: true, exclusion: {in: [true]}
  end

  test "#render encodes validation attributes onto the element" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.text_field :content %>
      <% end %>
    ERB

    assert_element "input", required: true, maxlength: 100, "data-validation-messages": true, count: 1
  end

  test "#render omits Active Model validation message translations from [type=hidden]" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.hidden_field :content %>
      <% end %>
    ERB

    assert_element "input", type: "hidden", "data-validation-messages": false, visible: false, count: 1
  end

  test "#render encodes Active Model validation message translations into text fields" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.text_field :content %>
      <% end %>
    ERB

    assert_field count: 1 do |input|
      messages = JSON.parse(input["data-validation-messages"])

      assert_equal "is invalid", messages["badInput"]
      assert_equal "can't be blank", messages["valueMissing"]
    end
  end

  test "#render encodes Active Model validation message translations into select elements" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.select :content, [true, false] %>
      <% end %>
    ERB

    assert_element "select", "data-validation-messages": true, count: 1 do |select|
      messages = JSON.parse(select["data-validation-messages"])

      assert_equal "is invalid", messages["badInput"]
      assert_equal "can't be blank", messages["valueMissing"]
    end
  end

  test "#render skips validation messages when `model: nil`" do
    render inline: <<~ERB
      <%= fields model: nil, scope: :message do |form| %>
        <%= form.text_field :content %>
      <% end %>
    ERB

    assert_element "input", "input[data-validation-messages]": false, count: 1
  end

  test "#render omits aria-describedby when the field is valid" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.text_field :content %>
        <%= form.validation_message :content %>
      <% end %>
    ERB

    assert_element "input", "aria-describedby": false, count: 1
    assert_element "span", id: "#{@object_name}_content_validation_message", count: 1
  end

  test "#render omits aria-describedby when the field is [type=hidden]" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.hidden_field :content %>
      <% end %>
    ERB

    assert_element "input", type: "hidden", visible: false, "aria-describedby": false, count: 1
  end

  test "#render encodes aria-describedby reference to the validation message element when the text field is invalid" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.text_field :content %>
        <%= form.validation_message :content %>
      <% end %>
    ERB

    assert_element "input", "aria-describedby": "#{@object_name}_content_validation_message", count: 1 do |input|
      assert_matches_selector input, :field, described_by: "can't be blank"
    end
    assert_element "span", id: "#{@object_name}_content_validation_message", count: 1
  end

  test "#render encodes aria-describedby reference to the validation message element when the select field is invalid" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <%= form.select :published, [true, false], prompt: true %>
        <%= form.validation_message :published %>
      <% end %>
    ERB

    assert_element "select", "aria-describedby": "#{@object_name}_published_validation_message" do |select|
      assert_matches_selector select, :select, described_by: "can't be blank"
    end
    assert_element "span", id: "#{@object_name}_published_validation_message", count: 1
  end

  test "#render prepends to existing aria-describedby values when the field is invalid" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.text_field :content, aria: { describedby: "other_description" } %>
        <%= form.validation_message :content %>
        <span id="other_description">Optional</span>
      <% end %>
    ERB

    assert_element "input", "aria-describedby": "#{@object_name}_content_validation_message other_description", count: 1 do |input|
      assert_matches_selector input, :field, described_by: "can't be blank"
      assert_matches_selector input, :field, described_by: "Optional"
    end
  end

  test "#render encodes aria-errormessage reference into text field with form builder namespace" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= fields model: message, namespace: "namespace" do |form| %>
      <%= form.text_field :content %>
      <%= form.validation_message :content %>
      <% end %>
    ERB

    assert_element "input", "aria-errormessage": "namespace_#{@object_name}_content_validation_message", count: 1
    assert_element "span", id: "namespace_#{@object_name}_content_validation_message", count: 1
  end

  test "#render encodes aria-errormessage reference into select with form builder namespace" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= fields model: message, namespace: "namespace" do |form| %>
      <%= form.select :published, [true, false], prompt: true %>
      <%= form.validation_message :published %>
      <% end %>
    ERB

    assert_element "select", "aria-errormessage": "namespace_#{@object_name}_published_validation_message", count: 1
    assert_element "span", id: "namespace_#{@object_name}_published_validation_message", count: 1
  end

  test "#render omits aria-errormessage from [type=hidden]" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.hidden_field :content %>
      <% end %>
    ERB

    assert_element "input", type: "hidden", "aria-errormessage": false, visible: false, count: 1
  end

  test "#render encodes aria-errormessage reference to the validation message element when the field is valid" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.text_field :content %>
        <%= form.validation_message :content %>
      <% end %>
    ERB

    assert_element "input", "aria-errormessage": "#{@object_name}_content_validation_message", count: 1
  end

  test "#render encodes aria-errormessage reference to the validation message element when the field is invalid" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.text_field :content %>
        <%= form.validation_message :content %>
      <% end %>
    ERB

    assert_element "input", "aria-errormessage": "#{@object_name}_content_validation_message", count: 1
    assert_element "span", id: "#{@object_name}_content_validation_message", count: 1
  end

  test "#render encodes aria-errormessage reference with a nested form builder" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.fields :nested, model: message, index: 1 do |nested_form| %>
          <%= nested_form.text_field :content %>
          <%= nested_form.validation_message :content %>
        <% end %>
      <% end %>
    ERB

    assert_element "input", "aria-errormessage": "#{@object_name}_nested_1_content_validation_message", count: 1
    assert_element "span", id: "#{@object_name}_nested_1_content_validation_message", count: 1
  end

  test "#render encodes aria-errormessage reference with a nested form builder's parent's namespace" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= fields model: message, namespace: "namespace" do |form| %>
        <%= form.fields :nested, model: message, index: 1 do |nested_form| %>
          <%= nested_form.text_field :content %>
          <%= nested_form.validation_message :content %>
        <% end %>
      <% end %>
    ERB

    assert_element "input", "aria-errormessage": "namespace_#{@object_name}_nested_1_content_validation_message", count: 1
    assert_element "span", id: "namespace_#{@object_name}_nested_1_content_validation_message", count: 1
  end

  test "#render sets aria-invalid on the text field when the instance is invalid" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.text_field :content %>
      <% end %>
    ERB

    assert_element "input", type: "text", "aria-invalid": "true", count: 1
  end

  test "#render sets aria-invalid on the select when the instance is invalid" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <%= form.select :published, [true, false], prompt: true %>
      <% end %>
    ERB

    assert_element "select", required: true, "aria-invalid": "true", count: 1
  end

  test "#render does not override [required] on the select" do
    message = Message.new

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.select :published, [true, false], {prompt: true}, required: false %>
      <% end %>
    ERB

    assert_element "select", required: false, count: 1
    assert_no_element "select", required: true
  end

  test "#render omits aria-invalid when the [type=hidden]" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.hidden_field :content %>
      <% end %>
    ERB

    assert_element "input", type: "hidden", "aria-invalid": false, visible: false, count: 1
  end

  test "#render sets aria-invalid when the checkbox is checked and the field is invalid" do
    message = Message.new(published: true).tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.check_box :published %>
      <% end %>
    ERB

    assert_checked_field type: "checkbox", count: 1 do |input|
      assert_matches_selector input, :element, "aria-invalid": "true"
    end
  end
end
