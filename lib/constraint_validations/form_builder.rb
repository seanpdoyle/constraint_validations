module ConstraintValidations
  class FormBuilder < ActionView::Helpers::FormBuilder
    include ConstraintValidations::FormBuilder::Extensions

    def self.validation_message_id(template, object_or_name, method, index: nil)
      template.field_id(object_or_name, method, :validation_message, index: index)
    end

    def self.errors(object, field, &block)
      validation_messages = object.respond_to?(:errors) ? object.errors[field] : []

      block ? yield(validation_messages) : validation_messages
    end
  end
end
