module ConstraintValidations
  class FormBuilder < ActionView::Helpers::FormBuilder
    include ConstraintValidations::FormBuilder::Extensions

    def self.validation_message_id(template, object_or_name, method, **options)
      if ::ActionView::VERSION::MAJOR < 7
        template = BackPorts.new(template)
      end

      template.field_id(object_or_name, method, :validation_message, **options)
    end

    def self.errors(object, field, &block)
      validation_messages = object.respond_to?(:errors) ? object.errors[field] : []

      block ? yield(validation_messages) : validation_messages
    end

    def self.visible?(tag_builder)
      if tag_builder.class.respond_to?(:field_type)
        tag_builder.class.field_type != "hidden"
      else
        true
      end
    end

    class BackPorts < SimpleDelegator
      #
      # Implmentation backported from
      # https://github.com/rails/rails/blob/v7.0.4.3/actionview/lib/action_view/helpers/form_tag_helper.rb
      #
      def field_id(object_name, method_name, *suffixes, index: nil, namespace: nil)
        if object_name.respond_to?(:model_name)
          object_name = object_name.model_name.singular
        end

        sanitized_object_name = object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").delete_suffix("_")

        sanitized_method_name = method_name.to_s.delete_suffix("?")

        [
          namespace,
          sanitized_object_name.presence,
          (index unless sanitized_object_name.empty?),
          sanitized_method_name,
          *suffixes,
        ].tap(&:compact!).join("_")
      end
    end
    private_constant :BackPorts
  end
end
