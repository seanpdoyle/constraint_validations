require "html5_validators"

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
        if FormBuilder.errors(@object, @method_name).any?
          @options["aria-invalid"] ||= "true"
        end

        super
      end
    end

    module CheckableAriaTagsExtension
      def render
        if FormBuilder.errors(@object, @method_name).any?
          @options["aria-invalid"] ||= ("true" if input_checked?(@options))
        end

        super
      end
    end

    module ValidationMessageExtension
      def render
        index = @options.fetch(:index, @auto_index)
        validation_message_id = FormBuilder.validation_message_id(@template_object, @object_name, @method_name, index: index, namespace: @options[:namespace])

        @options["aria-errormessage"] ||= validation_message_id

        if @object.present?
          config = Rails.configuration.constraint_validations
          source =
            if @object.respond_to?(@method_name)
              config.validation_messages_for_object
            else
              config.validation_messages_for_object_name
            end

          @options["data-validation-messages"] ||= source.call(**instance_values.to_options).to_json
        end

        if FormBuilder.errors(@object, @method_name).any?
          value = @options["aria-describedby"] || @options.dig(:aria, :describedby)
          tokens = value.to_s.split(/\s/)
          tokens.unshift validation_message_id

          if @options.dig(:aria, :describedby)
            @options.deep_merge! aria: { describedby: tokens }
          else
            @options.merge! "aria-describedby" => tokens.join(" ")
          end
        end

        super
      end
    end

    ActiveSupport.on_load :action_view do
      module ::ActionView
        module Helpers
          module Tags
            class Select
              prepend AriaTagsExtension
              prepend ValidationMessageExtension
            end

            class TextField
              prepend AriaTagsExtension
              prepend ValidationMessageExtension
            end

            class TextArea
              prepend AriaTagsExtension
              prepend ValidationMessageExtension
            end

            [RadioButton, CheckBox].each do |kls|
              kls.prepend CheckableAriaTagsExtension
              kls.prepend ValidationMessageExtension
            end
          end
        end
      end
    end

    ActiveSupport.on_load :action_text_rich_text do
      module ::ActionView
        module Helpers
          module Tags
            class ActionText
              prepend AriaTagsExtension
              prepend ValidationMessageExtension
            end
          end
        end
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
