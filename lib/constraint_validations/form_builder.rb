module ConstraintValidations
  class FormBuilder < ActionView::Helpers::FormBuilder
    include ConstraintValidations::FormBuilder::Extensions

    def self.validation_message_id(template, object_or_name, method, index: nil)
      if ::ActionView::VERSION::MAJOR < 7
        template = BackPorts.new(template)
      end

      template.field_id(object_or_name, method, :validation_message, index: index)
    end

    def self.errors(object, field, &block)
      validation_messages = object.respond_to?(:errors) ? object.errors[field] : []

      block ? yield(validation_messages) : validation_messages
    end

    class BackPorts < SimpleDelegator
      #
      # Implmentation backported from
      # https://github.com/rails/rails/blob/v7.0.0.alpha2/actionview/lib/action_view/helpers/form_tag_helper.rb#L81-L115
      #
      def field_id(object_name, method_name, *suffixes, index: nil)
        if object_name.respond_to?(:model_name)
          object_name = object_name.model_name.singular
        end

        sanitized_object_name = object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").delete_suffix("_")

        sanitized_method_name = method_name.to_s.delete_suffix("?")

        # a little duplication to construct fewer strings
        if sanitized_object_name.empty?
          sanitized_method_name
        elsif suffixes.any?
          [sanitized_object_name, index, sanitized_method_name, *suffixes].compact.join("_")
        elsif index
          "#{sanitized_object_name}_#{index}_#{sanitized_method_name}"
        else
          "#{sanitized_object_name}_#{sanitized_method_name}"
        end
      end
    end
    private_constant :BackPorts
  end
end
