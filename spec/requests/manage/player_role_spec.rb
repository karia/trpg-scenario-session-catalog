require "rails_helper"

RSpec.describe "The player role on the manage screen" do
  let(:person) { create(:person, display_name: "本人") }

  before { sign_in_as create(:person, roles: %w[admin]) }

  it "shows the player checkbox as ticked and not changeable" do
    get edit_manage_person_path(person)

    field = response.body[%r{<input[^>]*person_roles_player[^>]*>}]

    expect(field).to be_present
    expect(field).to include("checked")
    expect(field).to include("disabled")
  end

  it "keeps the person a player even when the form omits it" do
    patch manage_person_path(person), params: { person: { display_name: "本人", roles: [ "admin" ] } }

    expect(person.reload).to be_player
    expect(person.roles).to eq([ "admin" ])
  end

  it "does not fail when a submission still carries the player value" do
    patch manage_person_path(person), params: { person: { display_name: "本人", roles: [ "gm", "player" ] } }

    expect(response).to redirect_to(manage_people_path)
    expect(person.reload.roles).to eq([ "gm" ])
  end

  it "lists プレイヤー for everyone on the member index" do
    person

    get manage_people_path

    expect(response.body).to include("プレイヤー")
  end
end
