module HasAliases
  extend ActiveSupport::Concern

  included do
    attr_accessor :display_alias_id

    accepts_nested_attributes_for :aliases, allow_destroy: true,
      reject_if: ->(attrs) { attrs["id"].blank? && attrs["name"].blank? }

    before_validation :promote_selected_alias
  end

  def visible_aliases = aliases.select(&:visible?)

  private
    def promote_selected_alias
      selected_id = display_alias_id.presence
      return if selected_id.blank?

      selected = aliases.detect { |item| item.id.to_s == selected_id.to_s && !item.marked_for_destruction? }
      unless selected&.visible?
        errors.add(:display_alias_id, "は表示する名前から選んでください")
        return
      end

      previous_name = alias_display_name
      self.alias_display_name = selected.name
      selected.name = previous_name
      selected.visible = true
    end

    def alias_display_name
      public_send(self.class::DISPLAY_NAME_ATTRIBUTE)
    end

    def alias_display_name=(value)
      public_send("#{self.class::DISPLAY_NAME_ATTRIBUTE}=", value)
    end
end
