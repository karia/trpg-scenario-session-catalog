require "rails_helper"

# ADR-0001 は認可の漏れをそのまま情報漏えいとして扱う。役割ごとの可否を一覧で固定する。
RSpec.describe "Authorization matrix" do
  # current_person は未ログインでも Person 未紐づけでも nil になる。両方を明示的に置く。
  let(:anonymous) { nil }
  let(:unlinked) { nil }
  let(:no_role) { create(:person) }
  let(:gm) { create(:person, roles: %w[gm]) }
  let(:admin) { create(:person, roles: %w[admin]) }

  def allows?(person, policy_class, record, action)
    policy_class.new(person, record).public_send(action)
  end

  describe ScenarioPolicy do
    it "lets anyone read" do
      [ anonymous, unlinked, no_role, gm, admin ].each do |person|
        expect(allows?(person, described_class, Scenario.new, :show?)).to be(true)
      end
    end

    it "lets only editors write" do
      expect(allows?(anonymous, described_class, Scenario.new, :update?)).to be_falsey
      expect(allows?(unlinked, described_class, Scenario.new, :update?)).to be_falsey
      expect(allows?(no_role, described_class, Scenario.new, :update?)).to be_falsey
      expect(allows?(gm, described_class, Scenario.new, :update?)).to be(true)
      expect(allows?(admin, described_class, Scenario.new, :update?)).to be(true)
    end

    it "hides the preparation note from everyone until Phase 4" do
      [ anonymous, unlinked, no_role, gm, admin ].each do |person|
        expect(allows?(person, described_class, Scenario.new, :show_preparation_note?)).to be(false)
      end
    end
  end

  describe PersonPolicy do
    it "is admin only, including against GMs" do
      expect(allows?(gm, described_class, Person.new, :index?)).to be_falsey
      expect(allows?(gm, described_class, Person.new, :update?)).to be_falsey
      expect(allows?(admin, described_class, Person.new, :index?)).to be(true)
    end
  end

  describe UserPolicy do
    it "is admin only, so a GM cannot rebind accounts to people and grant themselves roles" do
      expect(allows?(anonymous, described_class, User.new, :index?)).to be_falsey
      expect(allows?(no_role, described_class, User.new, :index?)).to be_falsey
      expect(allows?(gm, described_class, User.new, :index?)).to be_falsey
      expect(allows?(gm, described_class, User.new, :update?)).to be_falsey
      expect(allows?(admin, described_class, User.new, :index?)).to be(true)
      expect(allows?(admin, described_class, User.new, :update?)).to be(true)
    end
  end

  describe "the manage entry points" do
    it "are editor-only, even though the public index? is wider" do
      expect(allows?(no_role, ScenarioPolicy, Scenario.new, :index?)).to be(true)
      expect(allows?(no_role, ScenarioPolicy, Scenario.new, :manage?)).to be_falsey
      expect(allows?(gm, ScenarioPolicy, Scenario.new, :manage?)).to be(true)
    end
  end

  describe GroupPolicy do
    it "is admin only" do
      expect(allows?(gm, described_class, Group.new, :index?)).to be_falsey
      expect(allows?(admin, described_class, Group.new, :index?)).to be(true)
    end
  end

  describe "scopes" do
    it "returns nothing to a GM for people and groups" do
      create(:person)
      create(:group)

      expect(PersonPolicy::Scope.new(gm, Person).resolve).to be_empty
      expect(GroupPolicy::Scope.new(gm, Group).resolve).to be_empty
      expect(UserPolicy::Scope.new(gm, User).resolve).to be_empty
    end

    it "returns the master tables to a GM, who edits scenarios" do
      create(:game_system)
      create(:author)

      expect(GameSystemPolicy::Scope.new(gm, GameSystem).resolve).not_to be_empty
      expect(AuthorPolicy::Scope.new(gm, Author).resolve).not_to be_empty
    end

    it "returns nothing from the master tables to someone with no role" do
      create(:game_system)

      expect(GameSystemPolicy::Scope.new(no_role, GameSystem).resolve).to be_empty
    end

    it "returns everything to an admin" do
      create(:group)

      expect(GroupPolicy::Scope.new(admin, Group).resolve).not_to be_empty
    end

    it "returns every scenario to an anonymous visitor" do
      create(:scenario)

      expect(ScenarioPolicy::Scope.new(anonymous, Scenario).resolve).not_to be_empty
    end
  end

  describe ApplicationPolicy do
    it "denies every action for a subclass that forgot to override" do
      policy = Class.new(ApplicationPolicy).new(admin, Object.new)

      %i[index? show? create? update? destroy?].each do |action|
        expect(policy.public_send(action)).to be(false)
      end
    end
  end
end
