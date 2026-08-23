require "rails_helper"

RSpec.describe "The player role on the manage screen" do
  let(:person) { create(:person, display_name: "本人") }

  before { sign_in_as create(:person, roles: %w[admin]) }

  it "shows the player checkbox as ticked and not changeable" do
    get edit_person_path(person)

    field = response.body[%r{<input[^>]*person_roles_player[^>]*>}]

    expect(field).to be_present
    expect(field).to include("checked")
    expect(field).to include("disabled")
  end

  it "keeps the person a player even when the form omits it" do
    patch person_path(person), params: { person: { display_name: "本人", roles: [ "admin" ] } }

    expect(person.reload).to be_player
    expect(person.roles).to eq([ "admin" ])
  end

  it "does not fail when a submission still carries the player value" do
    patch person_path(person), params: { person: { display_name: "本人", roles: [ "gm", "player" ] } }

    expect(response).to redirect_to(person_path(person))
    expect(person.reload.roles).to eq([ "gm" ])
  end

  it "lists プレイヤー as a role for everyone on the member index" do
    person

    get people_path

    card = Capybara.string(response.body).find("article", text: person.display_name)
    expect(card).to have_css("dt", text: "権限")
    expect(card).to have_css("dd", text: "プレイヤー", exact_text: true)
  end

  it "lists the stored roles after プレイヤー" do
    gm = create(:person, display_name: "GM の人", roles: %w[gm])

    get people_path

    card = Capybara.string(response.body).find("article", text: gm.display_name)
    expect(card).to have_css("dd", text: "プレイヤー、GM", exact_text: true)
  end
end
