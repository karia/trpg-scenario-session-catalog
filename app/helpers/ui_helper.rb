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
    url: :url_field
  }.freeze

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
    placeholder: nil, autocomplete: nil, inputmode: nil, data: {}, aria: {})
    error_id = form.field_id(attribute, :error) if form.object&.errors&.[](attribute)&.any?
    aria = aria.to_h.stringify_keys
    aria["describedby"] = [ aria["describedby"], described_by, error_id ].compact.flat_map { |ids| ids.to_s.split }.uniq.join(" ").presence
    data = data.to_h.merge(ui_error_id: error_id).compact
    input_options = {
      disabled:,
      required:,
      data:,
      aria:,
      class: "min-h-11 w-full rounded-ui-control border border-ui-outline-strong bg-ui-field-solid px-3 py-2 text-base text-ui-text placeholder:text-ui-text-muted focus:border-ui-focus focus:outline-none focus:ring-2 focus:ring-ui-focus/30 disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-ui-error aria-invalid:ring-1 aria-invalid:ring-ui-error"
    }
    input_options[:id] = id if id
    input_options[:placeholder] = placeholder if placeholder
    input_options[:autocomplete] = autocomplete if autocomplete
    input_options[:inputmode] = inputmode if inputmode

    render "shared/ui/input",
      form:,
      attribute:,
      input_method: INPUT_TYPES.fetch(type),
      input_options:
  end
end
