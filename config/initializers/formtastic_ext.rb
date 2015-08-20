Formtastic::Helpers::FormHelper.builder = FormtasticBootstrap::FormBuilder

module Formtastic
  module Helpers
    module InputHelper

      def content_input(content_attribute, options = {})
        options.reverse_merge!(
          :as => content_attribute.input_type,
          :label => content_attribute.name,
          :hint => content_attribute.description,
          :required => content_attribute.required
        )

        options.reverse_merge!(content_attribute.input_options)
        input_html_options = {}.tap do |hash|
          if content_attribute.limit_quantity.to_i > 0
            hash[:data] = {
              :limit_quantity => content_attribute.limit_quantity,
              :limit_unit => content_attribute.limit_unit
            }
          end
          if content_attribute.field_type == 'rich'
            (hash[:data] ||= {}).reverse_merge!(content_attribute.sir_trevor_limit_data)
          end
          if content_attribute.field_type == 'text'
            (hash[:data] ||= {}).reverse_merge!({"redactor-plugins" => Pig::configuration.try(:basic_redactor_plugins) || []})
          end
          if content_attribute.field_type == 'rich_content'
            (hash[:data] ||= {}).reverse_merge!({"redactor-plugins" => Pig::configuration.try(:redactor_plugins) || []})
          end
        end
        options[:input_html] = (options[:input_html] || {}).reverse_merge(input_html_options)
        (options[:input_html][:class] ||= "")  << "st-content hide" if content_attribute.field_type == 'rich'
        input(content_attribute.input_method, options)
      end

    end
  end
end

FormtasticBootstrap::Inputs::DateSelectInput.send(:remove_const,
                                                  'FRAGMENT_CLASSES')
FormtasticBootstrap::Inputs::DateSelectInput.send(:const_set,
                                                  'FRAGMENT_CLASSES',
                                                  {
                                                    :year   => "col-xs-4",
                                                    :month  => "col-xs-4",
                                                    :day    => "col-xs-4"
                                                  })
