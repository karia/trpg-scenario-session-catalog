class AddCharacterSheetDeadlineNoteToScenarios < ActiveRecord::Migration[8.1]
  def change
    add_column :scenarios, :character_sheet_deadline_note, :string
  end
end
