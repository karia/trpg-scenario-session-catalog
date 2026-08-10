require "rails_helper"

RSpec.describe "Favorites" do
  let(:scenario) { create(:scenario, title: "見本シナリオ") }

  it "is closed to a visitor who has not signed in" do
    post scenario_favorite_path(scenario)

    expect(response).to have_http_status(:not_found)
    expect(Favorite.count).to eq(0)
  end

  it "is closed to an account that is not linked to a person" do
    sign_in_as create(:user, person: nil)

    post scenario_favorite_path(scenario)

    expect(response).to have_http_status(:not_found)
    expect(Favorite.count).to eq(0)
  end

  it "adds and removes a favourite for the signed-in member" do
    person = create(:person)
    sign_in_as person

    expect { post scenario_favorite_path(scenario) }.to change(Favorite, :count).by(1)
    expect(person.reload).to be_favourite(scenario)

    expect { delete scenario_favorite_path(scenario) }.to change(Favorite, :count).by(-1)
    expect(person.reload).not_to be_favourite(scenario)
  end

  it "does not add the same scenario twice" do
    sign_in_as create(:person)
    post scenario_favorite_path(scenario)

    expect { post scenario_favorite_path(scenario) }.not_to change(Favorite, :count)
  end

  it "replaces only the button, without a full page load" do
    sign_in_as create(:person)

    post scenario_favorite_path(scenario), headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include("turbo-stream")
  end

  it "shows the favourite on the owner's profile" do
    person = create(:person)
    sign_in_as person
    post scenario_favorite_path(scenario)

    get person_path(person)

    expect(response.body).to include("見本シナリオ")
  end
end
