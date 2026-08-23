module UiHelper
  BUTTON_VARIANTS = {
    primary: "border-transparent bg-ui-action text-ui-on-action hover:bg-ui-action-hover active:bg-ui-action-active",
    secondary: "border-ui-outline-strong bg-ui-surface-solid text-ui-text hover:bg-ui-subtle active:bg-ui-field-solid",
    danger: "border-transparent bg-ui-danger text-ui-on-danger hover:brightness-110 active:brightness-90"
  }.freeze
  BUTTON_SIZES = {
    small: "px-3",
    medium: "px-4"
  }.freeze
  INPUT_TYPES = {
    text: :text_field,
    email: :email_field,
    password: :password_field,
    search: :search_field,
    telephone: :telephone_field,
    url: :url_field,
    number: :number_field,
    date: :date_field,
    time: :time_field
  }.freeze

  CONTROL_CLASSES = "min-h-11 w-full rounded-ui-control border border-ui-outline-strong bg-ui-field-solid px-3 py-2 text-base text-ui-text placeholder:text-ui-text-muted focus:border-ui-focus focus:outline-none focus:ring-2 focus:ring-ui-focus/30 disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-ui-error aria-invalid:ring-1 aria-invalid:ring-ui-error".freeze

  def ui_button(label, variant: :primary, size: :medium, type: "button", disabled: false, id: nil, data: {}, aria: {})
    render "shared/ui/button",
      label:,
      href: nil,
      variant_classes: BUTTON_VARIANTS.fetch(variant),
      size_classes: BUTTON_SIZES.fetch(size),
      type:,
      disabled:,
      id:,
      data:,
      aria:
  end

  def ui_button_link(label, href:, variant: :primary, size: :medium, data: {}, aria: {})
    render "shared/ui/button",
      label:,
      href:,
      variant_classes: BUTTON_VARIANTS.fetch(variant),
      size_classes: BUTTON_SIZES.fetch(size),
      type: nil,
      disabled: false,
      id: nil,
      data:,
      aria:
  end

  def ui_field(form, attribute, label: nil, description: nil, required: false, &block)
    description_id = form.field_id(attribute, :description) if description.present?
    error_messages = form.object&.errors&.full_messages_for(attribute) || []
    error_id = form.field_id(attribute, :error) if error_messages.any?
    described_by = [ description_id, error_id ].compact.join(" ").presence
    input = capture({ described_by: }, &block)

    render "shared/ui/field",
      form:,
      attribute:,
      label: label || form.object.class.human_attribute_name(attribute),
      description:,
      description_id:,
      required:,
      input:,
      error_messages:,
      error_id:
  end

  def ui_input(form, attribute, type: :text, described_by: nil, disabled: false, required: false, id: nil,
    placeholder: nil, autocomplete: nil, inputmode: nil, min: nil, max: nil, step: nil, data: {}, aria: {})
    error_id = form.field_id(attribute, :error) if form.object&.errors&.[](attribute)&.any?
    aria = aria.to_h.stringify_keys
    aria["describedby"] = [ aria["describedby"], described_by, error_id ].compact.flat_map { |ids| ids.to_s.split }.uniq.join(" ").presence
    data = data.to_h.merge(ui_error_id: error_id).compact
    input_options = {
      disabled:,
      required:,
      data:,
      aria:,
      class: CONTROL_CLASSES
    }
    input_options[:id] = id if id
    input_options[:placeholder] = placeholder if placeholder
    input_options[:autocomplete] = autocomplete if autocomplete
    input_options[:inputmode] = inputmode if inputmode
    input_options[:min] = min if min
    input_options[:max] = max if max
    input_options[:step] = step if step

    render "shared/ui/input",
      form:,
      attribute:,
      input_method: INPUT_TYPES.fetch(type),
      input_options:
  end

  def ui_textarea(form, attribute, described_by: nil, rows: 4, required: false, disabled: false, id: nil, data: {}, aria: {})
    options = ui_control_options(form, attribute, described_by:, required:, disabled:, id:, data:, aria:)
    render "shared/ui/textarea", form:, attribute:, rows:, input_options: options
  end

  def ui_select(form, attribute, choices, described_by: nil, include_blank: nil, required: false, disabled: false,
    id: nil, data: {}, aria: {})
    options = ui_control_options(form, attribute, described_by:, required:, disabled:, id:, data:, aria:)
    render "shared/ui/select", form:, attribute:, choices:, select_options: { include_blank: }, input_options: options
  end

  def ui_checkbox(form, attribute, label:, checked_value: "1", unchecked_value: "0", disabled: false, id: nil,
    data: {}, aria: {})
    render "shared/ui/checkbox", form:, attribute:, label:, checked_value:, unchecked_value:, disabled:, id:, data:, aria:
  end

  def ui_collection_checkboxes(form, attribute, collection, value_method:, text_method:)
    form.collection_check_boxes(attribute, collection, value_method, text_method) do |builder|
      render "shared/ui/collection_checkbox", builder:
    end
  end

  def ui_file_input(form, attribute, accept:, described_by: nil)
    error_id = form.field_id(attribute, :error) if form.object&.errors&.[](attribute)&.any?
    form.file_field attribute, accept:, data: { ui_error_id: error_id }.compact,
      aria: { describedby: [ described_by, error_id ].compact.join(" ").presence },
      class: "block min-h-11 w-full cursor-pointer rounded-ui-control border border-ui-outline-strong bg-ui-field-solid text-sm text-ui-text file:mr-3 file:min-h-11 file:border-0 file:bg-ui-subtle file:px-3 file:py-2 file:font-bold file:text-ui-text hover:file:bg-ui-action hover:file:text-ui-on-action"
  end

  def ui_radio(name, value, label:, checked:, id:, required: false, disabled: false, data: {}, aria: {})
    render "shared/ui/radio", name:, value:, label:, checked:, id:, required:, disabled:, data:, aria:
  end

  def ui_error_summary(record)
    render "shared/ui/error_summary", record:
  end

  def ui_repeatable_fields(form, association:, legend:, hint:, row_partial:, new_record:, add_label: "行を足す",
    row_local: :link, token: "NEW_RECORD")
    render "shared/ui/repeatable_fields", form:, association:, legend:, hint:, row_partial:, new_record:, add_label:,
      row_local:, token:
  end

  private
    def ui_control_options(form, attribute, described_by:, required:, disabled:, id:, data:, aria:)
      error_id = form.field_id(attribute, :error) if form.object&.errors&.[](attribute)&.any?
      aria = aria.to_h.stringify_keys
      aria["describedby"] = [ aria["describedby"], described_by, error_id ].compact.flat_map { |ids| ids.to_s.split }.uniq.join(" ").presence
      data = data.to_h.merge(ui_error_id: error_id).compact
      options = { required:, disabled:, data:, aria:, class: CONTROL_CLASSES }
      options[:id] = id if id
      options
    end
end
