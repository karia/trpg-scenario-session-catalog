module HasAliases
  extend ActiveSupport::Concern

  included do
    attr_accessor :display_alias_key

    accepts_nested_attributes_for :aliases, allow_destroy: true,
      reject_if: ->(attrs) { attrs["id"].blank? && attrs["name"].blank? }

    before_validation :promote_selected_alias
    after_validation :restore_names_after_failed_promotion
  end

  def visible_aliases = aliases.select(&:visible?)

  private
    def promote_selected_alias
      selected_key = display_alias_key.presence
      return if selected_key.blank? || @promotion_applied

      selected = aliases.detect do |item|
        [ item.selection_key, item.id ].compact.map(&:to_s).include?(selected_key.to_s) && !item.marked_for_destruction?
      end
      unless selected&.visible?
        errors.add(:display_alias_key, "は表示する名前から選んでください")
        return
      end

      @promoted_alias = selected
      @previous_display_name = alias_display_name
      @promotion_applied = true
      self.alias_display_name = selected.name
      selected.name = @previous_display_name
      selected.visible = true
    end

    def restore_names_after_failed_promotion
      return unless errors.any? && @promotion_applied

      selected_name = alias_display_name
      self.alias_display_name = @previous_display_name
      @promoted_alias.name = selected_name
      @promotion_applied = false
    end

    def alias_display_name
      public_send(self.class::DISPLAY_NAME_ATTRIBUTE)
    end

    def alias_display_name=(value)
      public_send("#{self.class::DISPLAY_NAME_ATTRIBUTE}=", value)
    end
end
