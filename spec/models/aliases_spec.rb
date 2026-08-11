require "rails_helper"

RSpec.describe "Aliases" do
  shared_examples "a named record with aliases" do |factory, display_attribute, alias_class|
    let(:record) { create(factory) }

    it "holds multiple visible and hidden names" do
      record.aliases.create!(name: "公開名", visible: true)
      record.aliases.create!(name: "非公開名", visible: false)

      expect(record.visible_aliases.map(&:name)).to eq([ "公開名" ])
    end

    it "promotes a visible alias and keeps the former display name" do
      former_name = record.public_send(display_attribute)
      selected = record.aliases.create!(name: "新しい表示名", visible: true)

      expect(record.update(display_alias_key: selected.id)).to be(true)
      expect(record.reload.public_send(display_attribute)).to eq("新しい表示名")
      expect(selected.reload.attributes.slice("name", "visible")).to eq("name" => former_name, "visible" => true)
    end

    it "does not promote a hidden alias" do
      selected = record.aliases.create!(name: "非公開名", visible: false)

      expect(record.update(display_alias_key: selected.id)).to be(false)
      expect(record.errors[:display_alias_key]).to be_present
    end

    it "restores the names when another validation rejects the promotion" do
      selected = record.aliases.create!(name: "新しい表示名", visible: true)
      record.public_send("#{display_attribute}=", "")

      expect(record.update(display_alias_key: selected.id)).to be(false)
      expect(record.public_send(display_attribute)).to eq("")
      expect(selected.name).to eq("新しい表示名")
    end

    it "removes aliases with the parent" do
      record.aliases.create!(name: "別名")

      expect { record.destroy! }.to change(alias_class, :count).by(-1)
    end
  end

  describe GameSystem do
    it_behaves_like "a named record with aliases", :game_system, :name, GameSystemAlias
  end

  describe Author do
    it_behaves_like "a named record with aliases", :author, :name, AuthorAlias
  end

  describe Person do
    it_behaves_like "a named record with aliases", :person, :display_name, PersonAlias
  end
end
