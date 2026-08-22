ActionView::Base.field_error_proc = proc do |html_tag, instance|
  unless html_tag.match?(/\A<(input|select|textarea)\b/)
    next html_tag
  end

  fragment = Nokogiri::HTML.fragment(html_tag)
  field = fragment.at_css("input, select, textarea")
  unless field&.[]("id")
    next html_tag
  end

  external_error_id = field.delete("data-ui-error-id")&.to_s.presence
  error_id = external_error_id.presence || "#{field['id']}_error"
  describedby = field["aria-describedby"].to_s.split
  field["aria-invalid"] = "true"
  field["aria-describedby"] = (describedby << error_id).uniq.join(" ")
  method_name = instance.instance_variable_get(:@method_name)
  message = instance.object.errors.full_messages_for(method_name).join("、")
  attribute = ERB::Util.html_escape(method_name)
  next fragment.to_html.html_safe if external_error_id

  "#{fragment.to_html}<span id=\"#{ERB::Util.html_escape(error_id)}\" class=\"sr-only\" data-error-attribute=\"#{attribute}\">#{ERB::Util.html_escape(message)}</span>".html_safe
end
