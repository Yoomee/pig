class FileWithPreviewInput < FormtasticBootstrap::Inputs::FileInput

  def to_html
    bootstrap_wrapping do
      out = ''
      if object.send(input_name) && object.errors[input_name].blank?
        out << "<p><em><a href='#{object.send(input_name).url}' target='_blank'>#{object.send(input_name).name}</a></em></p>"
      end
      out << '<div class="file-inputs">'
      out << builder.file_field(method, input_html_options)
      if object.send("#{input_name}_uid").present?
        out << template.content_tag(:label, :class => 'checkbox remove-file') do
          builder.check_box("remove_#{input_name}") + " Remove #{label_text.downcase.gsub('<abbr title="required">*</abbr>', '')}"
        end
      end
      out << '</div>'
    end << '<div class="clearfix"></div>'.html_safe
  end

end
