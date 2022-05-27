require "html5_validators"

module ConstraintValidations
  class Engine < ::Rails::Engine
    isolate_namespace ConstraintValidations

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
        index = @options.fetch("index", @auto_index)
        validation_message_id = FormBuilder.validation_message_id(@template_object, @object || @object_name, @method_name, index: index)

        @options["aria-errormessage"] ||= validation_message_id

        if @object.present?
          @options["data-validation-messages"] ||= @template_object.render(
            partial: "validation_messages",
            locals: instance_values.symbolize_keys,
            formats: :json
          )
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
