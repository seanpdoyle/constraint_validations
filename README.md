# Constraint Validations

Integrate ActiveModel::Validations, ActionView, and Browser-provided Constraint Validation API

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

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'constraint_validations'
```

And then execute:
```bash
$ bundle
```

## Testing it out locally

To test this out on your own, clone the repository and run the `bin/setup`
script, then run the test suite by running `bin/rails test:all`.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
