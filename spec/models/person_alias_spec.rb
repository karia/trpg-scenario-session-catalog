require "rails_helper"

RSpec.describe PersonAlias do
  it "requires a name" do
    expect(build(:person_alias, name: "")).not_to be_valid
  end

  it "records where the alias is used, since names differ per Discord server" do
    person = create(:person)
    person.person_aliases.create!(name: "べつの名前", context: "とあるサーバ")

    expect(person.person_aliases.sole.context).to eq("とあるサーバ")
  end

  it "allows the same person to hold several aliases" do
    person = create(:person)
    person.person_aliases.create!(name: "A")
    person.person_aliases.create!(name: "B")

    expect(person.person_aliases.map(&:name)).to contain_exactly("A", "B")
  end

  it "goes away with the person" do
    person = create(:person)
    person.person_aliases.create!(name: "A")

    expect { person.destroy }.to change(described_class, :count).by(-1)
  end
end
