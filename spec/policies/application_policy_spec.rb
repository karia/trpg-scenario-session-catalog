require "rails_helper"

RSpec.describe ApplicationPolicy do
  subject(:policy) { described_class.new(nil, Object.new) }

  it "denies every action by default" do
    expect(policy.index?).to be(false)
    expect(policy.show?).to be(false)
    expect(policy.create?).to be(false)
    expect(policy.new?).to be(false)
    expect(policy.update?).to be(false)
    expect(policy.edit?).to be(false)
    expect(policy.destroy?).to be(false)
  end

  describe ApplicationPolicy::Scope do
    it "resolves to an empty scope by default" do
      scope = described_class.new(nil, ActiveStorage::Blob.all)

      expect(scope.resolve).to be_empty
    end
  end
end
