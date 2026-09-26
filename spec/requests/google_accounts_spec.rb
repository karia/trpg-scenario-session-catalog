require "rails_helper"

RSpec.describe "Google accounts" do
  let(:person) { create(:person) }

  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "10000001",
      info: { email: "google@example.com", name: "Google User" },
      credentials: { refresh_token: "refresh-token", scope: "email profile" }
    )
  end

  it "links Google to the signed-in member" do
    sign_in_as person

    post "/auth/google_oauth2"
    follow_redirect!

    expect(response).to redirect_to(person_path(person))
    expect(person.users.find_by(provider: "google_oauth2")).to have_attributes(
      google_refresh_token: "refresh-token", google_scopes: "email profile"
    )
  end

  it "requests offline access without YouTube for a member without a privileged role" do
    sign_in_as person
    OmniAuth.config.test_mode = false

    post "/auth/google_oauth2"

    query = Rack::Utils.parse_query(URI(response.location).query)
    expect(query.fetch("scope").split).to contain_exactly("email", "profile")
    expect(query).to include("access_type" => "offline", "prompt" => "consent select_account")
  end

  it "does not let a request override the scopes allowed for the member" do
    sign_in_as person
    OmniAuth.config.test_mode = false

    post "/auth/google_oauth2", params: { scope: "email profile https://www.googleapis.com/auth/youtube.force-ssl" }

    scopes = Rack::Utils.parse_query(URI(response.location).query).fetch("scope").split
    expect(scopes).to contain_exactly("email", "profile")
  end

  it "also requests youtube.force-ssl for a GM or administrator" do
    %w[gm admin].each do |role|
      sign_in_as create(:person, roles: [ role ])
      OmniAuth.config.test_mode = false

      post "/auth/google_oauth2"

      scopes = Rack::Utils.parse_query(URI(response.location).query).fetch("scope").split
      expect(scopes).to include("https://www.googleapis.com/auth/youtube.force-ssl")
      OmniAuth.config.test_mode = true
    end
  end

  it "does not link Google for a signed-out visitor" do
    expect {
      post "/auth/google_oauth2"
      follow_redirect!
    }.not_to change(User, :count)

    expect(response).to have_http_status(:not_found)
  end

  it "lets the member unlink Google from their profile" do
    google = create(:user, person:, google_refresh_token: "refresh-token", google_scopes: "email")
    sign_in_as person
    allow(GoogleTokenRevoker).to receive(:revoke)

    delete person_google_account_path(person)

    expect(response).to redirect_to(person_path(person))
    expect(google.reload.person).to be_nil
  end

  it "lets an admin unlink another member's Google account" do
    google = create(:user, person:, google_refresh_token: "refresh-token")
    sign_in_as create(:person, roles: %w[admin])
    allow(GoogleTokenRevoker).to receive(:revoke)

    delete person_google_account_path(person)

    expect(response).to redirect_to(person_path(person))
    expect(google.reload.person).to be_nil
  end

  it "ignores a submitted target and links Google to the signed-in admin" do
    admin = create(:person, roles: %w[admin])
    sign_in_as admin

    post "/auth/google_oauth2", params: { person_id: person.id }
    follow_redirect!

    expect(response).to redirect_to(person_path(admin))
    expect(person.users.where(provider: "google_oauth2")).to be_empty
    expect(admin.users.where(provider: "google_oauth2")).to exist
  end

  it "shows the link only on the member's own profile" do
    sign_in_as person

    get person_path(person)
    expect(Capybara.string(response.body)).to have_button("Googleを連携")

    get person_path(create(:person))
    expect(Capybara.string(response.body)).to have_no_button("Googleを連携")
  end

  it "hides another member's Google account from a regular member" do
    create(:user, person:, email: "private@example.com", google_refresh_token: "refresh-token")
    sign_in_as create(:person)

    get person_path(person)

    expect(response.body).not_to include("Google連携", "private@example.com")
  end
end
