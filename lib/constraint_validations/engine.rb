require "html5_validators"
require "html5_validators/active_model/helper_methods"
require "html5_validators/active_model/validations"

module ConstraintValidations
  class Engine < ::Rails::Engine
    isolate_namespace ConstraintValidations

    config.constraint_validations = ActiveSupport::InheritableOptions.new(
      validation_messages_for_object: lambda do |object:, method_name:, **options|
        {
          badInput: object.errors.generate_message(method_name, :invalid),
          valueMissing: object.errors.generate_message(method_name, :blank),
        }
      end,
      validation_messages_for_object_name: lambda do |**options|
        {
          badInput: I18n.translate(:invalid, scope: "errors.messages"),
          valueMissing: I18n.translate(:blank, scope: "errors.messages"),
        }
      end
    )

    module AriaTagsExtension
      def render
        attributes = @options

        if @html_options.is_a?(Hash)
          attributes = @html_options
          attributes.reverse_merge!("required" => @options.delete("required"))
        end

        if FormBuilder.errors(@object, @method_name).any? && FormBuilder.visible?(self)
          attributes["aria-invalid"] ||= "true"
        end

        super
      end
    end

    module CheckableAriaTagsExtension
      def render
        if FormBuilder.errors(@object, @method_name).any? && FormBuilder.visible?(self)
          @options["aria-invalid"] ||= ("true" if input_checked?(@options))
        end

        super
      end
    end

    module ValidationMessageExtension
      def render
        index = @options.fetch(:index, @auto_index)
        validation_message_id = FormBuilder.validation_message_id(@template_object, @object_name, @method_name, index: index, namespace: @options[:namespace])

        attributes = @options

        if @html_options.is_a?(Hash)
          attributes = @html_options
          attributes.reverse_merge!("required" => @options.delete("required"))
        end

        if FormBuilder.visible?(self)
          attributes["aria-errormessage"] ||= validation_message_id
        end

        if @object.present? && FormBuilder.visible?(self)
          config = Rails.configuration.constraint_validations
          source =
            if @object.respond_to?(@method_name)
              config.validation_messages_for_object
            else
              config.validation_messages_for_object_name
            end

          attributes["data-validation-messages"] ||= source.call(**instance_values.to_options).to_json
        end

        if FormBuilder.errors(@object, @method_name).any? && FormBuilder.visible?(self)
          value = attributes["aria-describedby"] || attributes.dig(:aria, :describedby)
          tokens = value.to_s.split(/\s/)
          tokens.unshift validation_message_id

          if attributes.dig(:aria, :describedby)
            attributes.deep_merge! aria: { describedby: tokens }
          else
            attributes.merge! "aria-describedby" => tokens.join(" ")
          end
        end

        super
      end
    end

    ActiveSupport.on_load :action_view do
      [
        ::ActionView::Helpers::Tags::Select,
        ::ActionView::Helpers::Tags::TextField,
        ::ActionView::Helpers::Tags::TextArea,
      ].each do |klass|
        klass.prepend AriaTagsExtension
        klass.prepend ValidationMessageExtension
      end

      [
        ::ActionView::Helpers::Tags::RadioButton,
        ::ActionView::Helpers::Tags::CheckBox,
      ].each do |klass|
        klass.prepend CheckableAriaTagsExtension
        klass.prepend ValidationMessageExtension
      end
    end


    ActiveSupport.on_load :action_controller_base do
      default_form_builder ConstraintValidations::FormBuilder
    end

    initializer "constraint_validations.assets" do |app|
      app.config.assets.precompile += %w(
        constraint_validations.js
        constraint_validations.js.map
        constraint_validations.es.js
        constraint_validations.es.js.map
      )
    end
  end
end
