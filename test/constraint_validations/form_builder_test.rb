require "test_helper"

class ConstraintValidations::FormBuilderTest < ConstraintValidations::TestCase
  Message = Class.new do
    include ActiveModel::Model

    attr_accessor :content

    validates :content, presence: true
  end

  setup { @object_name = "form_builder_test_message" }

  test "#validation_message_template renders a <template> element" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.validation_message_template do |messages, tag| %>
          <%= tag.span messages.to_sentence, class: "errors" %>
        <% end %>
      <% end %>
    ERB

    assert_element "template", "data-validation-message-template": true, visible: false do |template|
      assert_css template, "span:empty", class: "errors", id: false, count: 1
    end
  end

  test "#validation_message_template renders the default template when a block is omitted" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.validation_message_template %>
      <% end %>
    ERB

    assert_element "template", "data-validation-message-template": true, visible: false do |template|
      assert_css template, "span:empty", id: false, count: 1
    end
  end

  test "#validation_message renders the default validation message template" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.validation_message :content %>
      <% end %>
    ERB

    assert_element "span", id: "#{@object_name}_content_validation_message", text: "can't be blank", count: 1
  end

  test "#validation_message renders messages using the form's message template" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.validation_message_template do |messages, tag| %>
          <%= tag.span messages.to_sentence, class: "error" %>
        <% end %>
        <%= form.validation_message :content %>
      <% end %>
    ERB

    assert_element "span", id: "#{@object_name}_content_validation_message", class: "error", text: "can't be blank", count: 1
  end

  test "#validation_message renders the validation message id with the namespace" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message, namespace: "namespace" do |form| %>
        <%= form.validation_message :content %>
      <% end %>
    ERB

    assert_element "span", id: "namespace_#{@object_name}_content_validation_message", text: "can't be blank", count: 1
  end

  test "#validation_message incorporates :index into deep nesting" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.fields model: message, index: 1, namespace: "child" do |child_form| %>
          <%= child_form.fields model: message, index: 0, namespace: "grandchild" do |grandchild_form| %>
            <%= grandchild_form.number_field :content %>
            <%= grandchild_form.validation_message :content %>
          <% end %>
        <% end %>
      <% end %>
    ERB

    assert_field described_by: "can't be blank"
  end

  test "#validation_message renders messages using the nested form's message template" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.validation_message_template do |messages, tag| %>
          <%= tag.span messages.to_sentence, class: "error" %>
        <% end %>

        <%= form.fields :nested, model: message, index: 1 do |nested_form| %>
          <%= nested_form.validation_message :content %>
        <% end %>
      <% end %>
    ERB

    assert_element "span", id: "#{@object_name}_nested_1_content_validation_message", class: "error", text: "can't be blank", count: 1
  end

  test "#validation_message renders messages using the overriding nested form's message template" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= form.validation_message_template do |messages, tag| %>
          <%= tag.span messages.to_sentence, class: "error" %>
        <% end %>

        <%= form.fields :nested, model: message, index: 1 do |nested_form| %>
          <%= nested_form.validation_message_template do |messages, tag| %>
            <%= tag.span messages.to_sentence, class: "nested-error" %>
          <% end %>

          <%= nested_form.validation_message :content %>
        <% end %>
        <%= form.validation_message :content %>
      <% end %>
    ERB

    assert_element "span", id: "#{@object_name}_nested_1_content_validation_message", class: "nested-error", text: "can't be blank", count: 1
  end

  test "#validation_message renders via block when provided" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <% form.validation_message :content do |messages, tag| %>
          <%= tag.div messages.to_sentence, class: "error" %>
        <% end %>
      <% end %>
    ERB

    assert_no_element "span"
    assert_element "div", id: "#{@object_name}_content_validation_message", class: "error", text: "can't be blank", count: 1
  end

  test "#validation_message_id generates a DOM id for the field when invalid" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= tag.span id: form.validation_message_id(:content) %>
      <% end %>
    ERB

    assert_element "span", id: "#{@object_name}_content_validation_message", count: 1
  end

  test "#validation_message_id returns the DOM id when the field is valid" do
    message = Message.new(content: "no empty!").tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <%= tag.span id: form.validation_message_id(:content) %>
      <% end %>
    ERB

    assert_element "span", id: "#{@object_name}_content_validation_message", count: 1
  end

  test "#errors yields messages to the block" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <% form.errors(:content) do |errors| %>
          <span><%= errors.to_sentence %></span>
        <% end %>
      <% end %>
    ERB

    assert_element "span", text: "can't be blank", count: 1
  end

  test "#errors returns messages when the block is omitted" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= fields model: message do |form| %>
        <span><%= form.errors(:content).to_sentence %></span>
      <% end %>
    ERB

    assert_element "span", text: "can't be blank", count: 1
  end
end
