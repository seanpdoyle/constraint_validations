require "test_helper"

class ConstraintValidations::FormBuilderTest < ActiveSupport::TestCase
  include Rails::Dom::Testing::Assertions

  def render(*arguments, renderer: ApplicationController.renderer, **options, &block)
    renderer.render(*arguments, **options, &block).tap { |html| @document_root_element = Nokogiri::HTML(html) }
  end

  def document_root_element
    @document_root_element.tap { |element| raise "Don't forget to call `render`" if element.nil? }
  end

  Message = Class.new do
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :content

    validates :content, presence: true
  end

  test "#validation_message_template renders a <template> element" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <%= form.validation_message_template do |messages, tag| %>
          <%= tag.span messages.to_sentence, class: "errors" %>
        <% end %>
      <% end %>
    ERB

    assert_select "template[data-validation-message-template]" do
      assert_select "span[class=?]:empty:not([id])", "errors", count: 1
    end
  end

  test "#validation_message_template renders the default template when a block is omitted" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <%= form.validation_message_template %>
      <% end %>
    ERB

    assert_select "template[data-validation-message-template]" do
      assert_select "span:empty:not([id])", count: 1
    end
  end

  test "#validation_message renders the default validation message template" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <%= form.validation_message :content %>
      <% end %>
    ERB

    assert_select "span[id=?]", "#{message.model_name.singular}_content_validation_message", text: "can't be blank", count: 1
  end

  test "#validation_message renders messages using the form's message template" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <%= form.validation_message_template do |messages, tag| %>
          <%= tag.span messages.to_sentence, class: "error" %>
        <% end %>
        <%= form.validation_message :content %>
      <% end %>
    ERB

    assert_select "span[id=?][class=?]", "#{message.model_name.singular}_content_validation_message", "error", text: "can't be blank", count: 1
  end

  test "#validation_message renders via block when provided" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <% form.validation_message :content do |messages, tag| %>
          <%= tag.div messages.to_sentence, class: "error" %>
        <% end %>
      <% end %>
    ERB

    assert_select "span", count: 0
    assert_select "div[id=?][class=?]", "#{message.model_name.singular}_content_validation_message", "error", text: "can't be blank", count: 1
  end

  test "#validation_message_id generates a DOM id for the field when invalid" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <%= tag.span id: form.validation_message_id(:content) %>
      <% end %>
    ERB

    assert_select "span[id=?]", "#{message.model_name.singular}_content_validation_message", count: 1
  end

  test "#validation_message_id returns nil when the field is valid" do
    message = Message.new(content: "no empty!").tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <%= tag.span id: form.validation_message_id(:content) %>
      <% end %>
    ERB

    assert_select "span:not([id])", count: 1
  end

  test "#errors yields messages to the block" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <% form.errors(:content) do |errors| %>
          <span><%= errors.to_sentence %></span>
        <% end %>
      <% end %>
    ERB

    assert_select "span", text: "can't be blank", count: 1
  end

  test "#errors returns messages when the block is omitted" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <span><%= form.errors(:content).to_sentence %></span>
      <% end %>
    ERB

    assert_select "span", text: "can't be blank", count: 1
  end
end
