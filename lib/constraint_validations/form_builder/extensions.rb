module ConstraintValidations
  class FormBuilder
    module Extensions
      def initialize(*)
        super

        @validation_message_template =
          if (parent_builder = @options[:parent_builder]) &&
              (inherited_validation_message_template = parent_builder.instance_values["validation_message_template"])
            inherited_validation_message_template
          else
            proc { |messages, tag| tag.span(messages.to_sentence) }
          end
      end

      # Captures a block for rendering both server- and client-side validation
      # messages
      #
      # The block accepts two arguments: <tt>errors</tt> and <tt>tag</tt>. The
      # <tt>errors</tt> argument is an Array of message Strings generated by an
      # <tt>ActiveModel::Errors</tt> instance. The
      # <tt>tag</tt> argument is an
      # <tt>ActionView::Helpers::TagHelpers::TagBuilder</tt> instance prepared
      # to render with an <tt>id</tt> attribute generated by a call to
      # <tt>validation_message_id</tt>.
      #
      # The resulting block will be evaluated by subsequent calls to
      # <tt>validation_message</tt> and will serve as a template for client-side
      # Constraint Validation message rendering.
      #
      # === Examples
      #
      #   <%= form.validation_message_template do |messages, tag| %>
      #     <%= tag.span messages.to_sentence, style: "color: red;" %>
      #   <% end %>
      #   <%# => <template data-validation-message-template> %>
      #   <%#      <span style="color: red;"></span>         %>
      #   <%#    </template>                                 %>
      #
      #   <%= form.validation_message :subject %>
      #   <%# => <span style="color: red;">can't be blank</span> %>
      #
      def validation_message_template(&block)
        @validation_message_template = block unless block.nil?

        content = @template.capture { @validation_message_template.call([], @template.tag) }

        @template.tag.template content, data: {validation_message_template: true}
      end

      # When the form's model is invalid, <tt>validation_message</tt> renders
      # HTML that's generated by iterating over a field's errors and passing
      # them as paramters to the block captured by the form's call to
      # <tt>validation_message_template</tt>. The resulting element's
      # <tt>id</tt> attribute will be generated by
      # <tt>validation_message_id</tt> to be referenced by field elements'
      # <tt>aria-describedby</tt> attributes.
      #
      # One-off overrides to the form's
      # <tt>validation_message_template</tt> can be made by passing a block to
      # <tt>validation_message</tt>.
      #
      # === Examples
      #
      #   <%= form.validation_message :subject %>
      #   <%# => <span id="subject_validation_message">can't be blank</span> %>
      #
      #   <% form.validation_message :subject do |errors, tag| %>
      #     <%= tag.span errors.to_sentence, class: "special-error" %>
      #   <% end %>
      #   <%# => <span id="subject_validation_message" class="special-error">can't be blank</span> %>
      #
      def validation_message(field, message: nil, **attributes, &block)
        errors field do |messages|
          if message.present?
            messages = Array(message)
          end

          @template.tag.with_options id: validation_message_id(field), **attributes do |tag|
            block ? yield(messages, tag) : @validation_message_template.call(messages, tag)
          end
        end
      end

      # When the form's model is invalid, <tt>validation_message_id</tt>
      # generates and returns a DOM id attribute for the field, otherwise
      # returns <tt>nil</tt>
      #
      # === Examples
      #
      #   <%= form.text_field :subject, aria: {describedby: form.validation_message_id(:subject)} %>
      #
      def validation_message_id(field, index: @index, namespace: @options[:namespace])
        FormBuilder.validation_message_id(@template, @object_name, field, index: index, namespace: namespace)
      end

      # Delegates to the <tt>FormBuilder#object</tt> property when possible, and
      # returns any error messages for the <tt>field</tt> argument. When passed a
      # block, <tt>#errors</tt> will yield the error messages as the block's first
      # parameter
      #
      # === Examples
      #
      #   <span><%= form.errors(:subject).to_sentence %></span>
      #
      #   <% form.errors(:subject) do |messages| %>
      #    <h2><%= pluralize(messages.count, "errors") %></h2>
      #
      #    <ul>
      #      <% messages.each do |message| %>
      #        <li><%= message %></li>
      #      <% end %>
      #    </ul>
      #   <% end %>
      #
      def errors(field, &block)
        FormBuilder.errors(object, field, &block)
      end
    end
  end
end
