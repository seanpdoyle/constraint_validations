require "test_helper"

class ConstraintValidations::AriaTagExtensionsTest < ActiveSupport::TestCase
  include Rails::Dom::Testing::Assertions

  def render(*arguments, renderer: ApplicationController.renderer, **options, &block)
    renderer.render(*arguments, **options, &block).tap { |html| @document_root_element = Nokogiri::HTML(html) }
  end

  def document_root_element
    @document_root_element.tap { |element| raise "Don't forget to call `render`" if element.nil? }
  end

  setup { @object_name = "aria_tag_extensions_test_message" }

  Message = Class.new do
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :content
    attribute :published, :boolean

    validates :content, presence: true, length: {maximum: 100}
    validates :published, exclusion: {in: [true]}
  end

  test "#render encodes validation attributes onto the element" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <%= form.text_field :content %>
      <% end %>
    ERB

    assert_select "input[data-validation-messages]", count: 1
    assert_select "input[required][maxlength=?]", "100", count: 1
  end

  test "#render encodes Active Model validation message translations" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <%= form.text_field :content %>
      <% end %>
    ERB

    assert_select "input", count: 1 do |input, *|
      messages = JSON.parse(input["data-validation-messages"])

      assert messages["badInput"] = "is invalid"
      assert messages["valueMissing"] = "can't be blank"
    end
  end

  test "#render skips validation messages when `form_with model: nil`" do
    render inline: <<~ERB
      <%= form_with model: nil, scope: :message, url: "#" do |form| %>
        <%= form.text_field :content %>
      <% end %>
    ERB

    assert_select "input[data-validation-messages]", count: 0
  end

  test "#render omits aria-describedby when the field is valid" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <%= form.text_field :content %>
        <%= form.validation_message :content %>
      <% end %>
    ERB

    assert_select "input[aria-describedby]", count: 0
    assert_select "span[id=?]", "#{@object_name}_content_validation_message", count: 1
  end

  test "#render encodes aria-describedby reference to the validation message element when the field is invalid" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <%= form.text_field :content %>
        <%= form.validation_message :content %>
      <% end %>
    ERB

    assert_select "input[aria-describedby~=?]", "#{@object_name}_content_validation_message", count: 1
    assert_select "span[id=?]", "#{@object_name}_content_validation_message", count: 1
  end

  test "#render prepends to existing aria-describedby values when the field is invalid" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <%= form.text_field :content, aria: { describedby: "other_description" } %>
        <%= form.validation_message :content %>
        <span id="other_description">Optional</span>
      <% end %>
    ERB

    assert_select "input[aria-describedby~=?]", "#{@object_name}_content_validation_message", count: 1
    assert_select "input[aria-describedby~=?]", "other_description", count: 1
  end

  test "#render encodes aria-errormessage reference with form builder namespace" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= fields model: message, namespace: "namespace" do |form| %>
      <%= form.text_field :content %>
      <%= form.validation_message :content %>
      <% end %>
    ERB

    assert_select "input[aria-errormessage~=?]", "namespace_#{@object_name}_content_validation_message", count: 1
    assert_select "span[id=?]", "namespace_#{@object_name}_content_validation_message", count: 1
  end

  test "#render encodes aria-errormessage reference to the validation message element when the field is valid" do
    render locals: {message: Message.new}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <%= form.text_field :content %>
        <%= form.validation_message :content %>
      <% end %>
    ERB

    assert_select "input[aria-errormessage~=?]", "#{@object_name}_content_validation_message", count: 1
  end

  test "#render encodes aria-errormessage reference to the validation message element when the field is invalid" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <%= form.text_field :content %>
        <%= form.validation_message :content %>
      <% end %>
    ERB

    assert_select "input[aria-errormessage~=?]", "#{@object_name}_content_validation_message", count: 1
    assert_select "span[id=?]", "#{@object_name}_content_validation_message", count: 1
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

    assert_select "input[aria-errormessage~=?]", "#{@object_name}_nested_1_content_validation_message", count: 1
    assert_select "span[id=?]", "#{@object_name}_nested_1_content_validation_message", count: 1
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

    assert_select "input[aria-errormessage~=?]", "namespace_#{@object_name}_nested_1_content_validation_message", count: 1
    assert_select "span[id=?]", "namespace_#{@object_name}_nested_1_content_validation_message", count: 1
  end

  test "#render sets aria-invalid when the instance is invalid" do
    message = Message.new.tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <%= form.text_field :content %>
      <% end %>
    ERB

    assert_select "input[type=?][aria-invalid=?]", "text", "true", count: 1
  end

  test "#render sets aria-invalid when the checkbox is checked and the field is invalid" do
    message = Message.new(published: true).tap(&:validate)

    render locals: {message: message}, inline: <<~ERB
      <%= form_with model: message, url: "#" do |form| %>
        <%= form.check_box :published %>
      <% end %>
    ERB

    assert_select "input[checked][type=?][aria-invalid=?]", "checkbox", "true", count: 1
  end
end
