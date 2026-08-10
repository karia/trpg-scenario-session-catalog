require "rails_helper"

RSpec.describe Authentication do
  it "is included in ApplicationController" do
    expect(ApplicationController.ancestors).to include(described_class)
  end

  it "hands Pundit the person rather than the account, so roles survive an account change" do
    expect(ApplicationController.instance_method(:pundit_user).owner).to eq(ApplicationController)
  end

  describe "#current_person" do
    it "is nil for a visitor who has not signed in" do
      controller = build_controller(session: {})

      expect(controller.current_person).to be_nil
    end

    it "is nil for an account that is not linked to a person yet" do
      user = create(:user, person: nil)
      controller = build_controller(session: { user_id: user.id })

      expect(controller.current_user).to eq(user)
      expect(controller.current_person).to be_nil
    end

    it "is the linked person once an admin has connected the account" do
      person = create(:person)
      user = create(:user, person: person)
      controller = build_controller(session: { user_id: user.id })

      expect(controller.current_person).to eq(person)
    end
  end

  def build_controller(session:)
    Class.new(ActionController::Base) do
      include Authentication

      define_method(:session) { session }
    end.new
  end
end
