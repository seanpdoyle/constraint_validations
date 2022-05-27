# Constraint Validations

Integrate ActiveModel::Validations, ActionView, and Browser-provided Constraint Validation API

**Currently testing against `rails@main` or `rails >= 6.2.0.alpha`**

## ActionView and Accessibility

The current Action View default configurations for `<form>` element construction
don't create accessible forms and fields.

Some of this work explores some possible extensions to Action View that could
improve Rails' baked in accessibility.

## ActionView and the Constraint Validations API

In addition to building more accessible forms and fields, the Action View
extensions introduce some new concepts and patterns to improve the developer
experience around rendering Active Model validations in server-generated
HTML.

There are also complementary client-side patterns introduced to integrate with
the Browser-provided Constraint Validations API (you know, that thing that every
Rails app on the planet opts-out of by declaring `[novalidate]` attributes).

## Usage

The `ConstraintValidations::FormBuilder` declares several new methods:

### `ConstraintValidations::FormBuilder#validation_message_template(&block)`

Captures a block for rendering both server- and client-side validation messages

The block accepts two arguments: `errors` and `tag`. The `errors` argument is an
Array of message Strings generated by an `ActiveModel::Errors` instance. The
`tag` argument is an `ActionView::Helpers::TagHelpers::TagBuilder` instance
prepared to render with an `id` attribute generated by a call to
`validation_message_id`.

The resulting block will be evaluated by subsequent calls to
`validation_message` and will serve as a template for client-side
Constraint Validation message rendering.

```html+erb
<%= form.validation_message_template do |messages, tag| %>
  <%= tag.span messages.to_sentence, style: "color: red;" %>
<% end %>
<%# => <template data-validation-message-template> %>
<%#      <span style="color: red;"></span>         %>
<%#    </template>                                 %>

<%= form.validation_message :subject %>
<%# => <span style="color: red;">can't be blank</span> %>
```

### `ConstraintValidations::FormBuilder#validation_message(field, **attributes, &block)`

When the form's model is invalid, `validation_message` renders HTML that's
generated by iterating over a field's errors and passing them as parameters to
the block captured by the form's call to `validation_message_template`. The
resulting element's `id` attribute will be generated by `validation_message_id`
to be referenced by field elements' `aria-describedby` attributes.

One-off overrides to the form's `validation_message_template` can be made by
passing a block to `validation_message`.

```html+erb
<%= form.validation_message :subject %>
<%# => <span id="subject_validation_message">can't be blank</span> %>

<% form.validation_message :subject do |errors, tag| %>
  <%= tag.span errors.to_sentence, class: "special-error" %>
<% end %>
<%# => <span id="subject_validation_message" class="special-error">can't be blank</span> %>
```

### `ConstraintValidations::FormBuilder#errors(field, &block)`

Delegates to the `FormBuilder#object` property when possible, and returns any
error messages for the `field` argument. When passed a block, `#errors` will
yield the error messages as the block's first parameter

```html+erb
<span><%= form.errors(:subject).to_sentence %></span>

<% form.errors(:subject) do |messages| %>
  <h2><%= pluralize(messages.count, "errors") %></h2>

  <ul>
    <% messages.each do |message| %>
      <li><%= message %></li>
    <% end %>
  </ul>
<% end %>
```

### `ConstraintValidations::FormBuilder#validation_message_id(field)`

When the form's model is invalid, `validation_message_id` generates and returns
a DOM id attribute for the field, otherwise returns `nil`

```html+erb
<%= form.text_field :subject, aria: {describedby: form.validation_message_id(:subject)} %>
```

### Examples

Consider the following model and controller classes for a hypothetical
`Message`:

```ruby
# app/models/message.rb
class Message < ApplicationRecord
  validates :content, length: {maximum: 280}
  validates :subject, presence: true, exclusion: {in: %w[forbidden]}
end
```

```ruby
# app/controllers/messages_controller.rb
class MessagesController < ApplicationController
  def new
    @message = Message.new
  end

  def create
    @message = Message.new(params.require(:message).permit(:subject, :contents))

    if @message.valid?
      redirect_back or_to: root_url
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

To integrate with Constraint Validations, make sure to call
`form.validation_message_template` and `form.validation_message` for each field:

```erb
<%# app/views/messages/new.html.erb %>
<%= form_with model: message do |form| %>
  <%= form.validation_message_template do |messages, tag| %>
    <%= tag.span messages.to_sentence, style: "color: red;" %>
  <% end %>

  <%= form.label :subject %>
  <%= form.text_field :subject %>
  <%= form.validation_message :subject %>

  <%= form.label :content %>
  <%= form.text_area :content %>
  <%= form.validation_message :content %>

  <%= form.button %>
<% end %>
```

## Ruby Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'constraint_validations'
```

And then execute:
```bash
$ bundle
```

By default, the engine will set the
[`default_form_builder`][default_form_builder] to
`ConstraintValidations::FormBuilder`. If your application is already using
another form builder class, you can extend it by mixing-in the
`ConstraintValidations::FormBuilder::Extensions` module.

[default_form_builder]: https://edgeapi.rubyonrails.org/classes/ActionController/FormBuilder.html

## JavaScript Installion

Next, make JavaScript available to the Asset Pipeline by requiring the library
in your `application.js`:

```diff
+//= require constraint_validations
 //= require_tree .
 //= require_self
```

If your application manages its JavaScript dependencies through [import maps][],
pin the dependency to `constraint_validations.es.js`:

```ruby
pin "constraint_validations", to: "constraint_validations.es.js"
```

[import maps]: https://github.com/rails/importmap-rails#importmap-for-rails

The next step depends on your application's JavaScript infrastructure.

If you're not depending on any frameworks or other tooling, listening for the
[DOMContentLoaded][] event is the most straightforward way to wire-up
`ConstraintValidations`:

```javascript
addEventListener("DOMContentLoaded", () => {
  ConstraintValidations.connect(document)
})
```

If your application is built with [Turbo][] or [Turbolinks][], attach an event
listener for the [turbo:load][] or [turbolinks:load] events, respectively:

```javascript
addEventListener("turbo:load", () => {
  ConstraintValidations.connect(document)
})
```

If your application uses Stimulus, declare a [controller][] and invoke
`ConstraintValidations.connect` within its [connect()][] lifecycle hook and
`ConstraintValidations.disconnect` within its [disconnect()][] lifecycle hook:

```javascript
import { Controller } from "@hotwired/stimulus"
import ConstraintValidations from "@seanpdoyle/constraint_validations"

export default class extends Controller {
  initialize() {
    this.validations = new ConstraintValidations(this.element)
  }

  connect() {
    this.validations.connect()
  }

  disconnect() {
    this.validations.disconnect()
  }
}
```

If you've called `connect()` on a `<form>` element's ancestor and you'd like to
opt-out of the validation behavior on the `<form>`, be sure to declare the
[novalidate][] attribute on the `<form>`.

### Disabling submit buttons when invalid

To disable a `<form>` element's `[type="submit]` elements, pass along a
`disableSubmitWhenInvalid:` option to either the `ConstraintValidations`
constructor, or to the `ConstraintValidations.connect` static method.

The value of `disableSubmitWhenInvalid:` can be a boolean, or a function that
accepts an Element (e.g. `document`, or a reference to an `HTMLFormElement`
instance) and returns a boolean.

[DOMContentLoaded]: https://developer.mozilla.org/en-US/docs/Web/API/Window/DOMContentLoaded_event
[Turbo]: https://turbo.hotwire.dev
[Turbolinks]: https://github.com/turbolinks/turbolinks
[turbo:load]: https://turbo.hotwire.dev/reference/events
[turbolinks:load]: https://github.com/turbolinks/turbolinks/#full-list-of-events
[controller]: https://stimulus.hotwire.dev/reference/controllers
[connect()]: https://stimulus.hotwire.dev/reference/lifecycle-callbacks#connection
[disconnect()]: https://stimulus.hotwire.dev/reference/lifecycle-callbacks#disconnection
[novalidate]: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form#attr-novalidate

## Testing it out locally

To test this out on your own, clone the repository and execute:

```shell
bundle install
bin/rails test test/**/*_test.rb
```

## Contributing

Read the [CONTRIBUTING.md](./CONTRIBUTING.md) guidelines to learn how to make
contributions.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
