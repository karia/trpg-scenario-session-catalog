require "rails_helper"

# ADR-0001 はセッションの可視性をこの Scope 1 箇所に集約すると決めている。
# 一覧、詳細、シナリオ詳細の履歴がすべてここを通るため、6 通りをここで固定する。
RSpec.describe PlaySessionPolicy do
  let(:group) { create(:group) }
  let(:participant) { create(:person, groups: [ group ]) }
  let(:session) { create(:play_session) }

  before { session.participations.create!(person: participant, role: :gm) }

  def visible_to(person)
    PlaySessionPolicy::Scope.new(person, PlaySession).resolve
  end

  it "hides everything from a visitor who has not signed in" do
    expect(visible_to(nil)).to be_empty
  end

  it "hides everything from an account that is not linked to a person" do
    # current_person は未紐づけのとき nil になる。未ログインと同じ扱いになることを固定する。
    expect(visible_to(nil)).to be_empty
  end

  it "hides a session from someone who shares no group with any participant" do
    stranger = create(:person, groups: [ create(:group) ])

    expect(visible_to(stranger)).to be_empty
  end

  it "shows a session to someone in the same group as a participant" do
    peer = create(:person, groups: [ group ])

    expect(visible_to(peer)).to include(session)
  end

  it "shows a session to the participant themselves, even with no group" do
    loner = create(:person)
    other = create(:play_session)
    other.participations.create!(person: loner, role: :player)

    expect(visible_to(loner)).to include(other)
  end

  it "shows everything to an admin" do
    admin = create(:person, roles: %w[admin])

    expect(visible_to(admin)).to include(session)
  end

  it "does not leak a session whose participants happen to share no group with anyone" do
    orphan = create(:play_session)
    orphan.participations.create!(person: create(:person), role: :gm)
    peer = create(:person, groups: [ group ])

    expect(visible_to(peer)).not_to include(orphan)
  end

  it "returns each session once when several participants share the viewer's group" do
    second = create(:person, groups: [ group ])
    session.participations.create!(person: second, role: :player)
    peer = create(:person, groups: [ group ])

    expect(visible_to(peer).to_a.count(session)).to eq(1)
  end

  describe "actions" do
    it "lets a viewer inside the scope see the session" do
      peer = create(:person, groups: [ group ])

      expect(described_class.new(peer, session).show?).to be(true)
    end

    it "refuses a viewer outside the scope" do
      stranger = create(:person)

      expect(described_class.new(stranger, session).show?).to be(false)
    end

    # 管理画面の入口。require_editor が先に効くが、ポリシー単体でも編集者に限る。
    it "opens the maintenance listing to editors only" do
      expect(described_class.new(create(:person, roles: %w[gm]), PlaySession).manage?).to be(true)
      expect(described_class.new(create(:person, roles: %w[admin]), PlaySession).manage?).to be(true)
      expect(described_class.new(create(:person), PlaySession).manage?).to be_falsey
      expect(described_class.new(create(:person), PlaySession).manage?).to be_falsey
      expect(described_class.new(nil, PlaySession).manage?).to be_falsey
    end

    it "lets GMs and admins write, and nobody else" do
      expect(described_class.new(create(:person, roles: %w[gm]), session).update?).to be(true)
      expect(described_class.new(create(:person, roles: %w[admin]), session).update?).to be(true)
      expect(described_class.new(create(:person), session).update?).to be_falsey
      expect(described_class.new(nil, session).update?).to be_falsey
    end

    it "shows the Cocofolia URL only to participants" do
      peer = create(:person, groups: [ group ])
      admin = create(:person, roles: %w[admin])
      gm = create(:person, roles: %w[gm])

      expect(described_class.new(participant, session).show_cocofolia_url?).to be(true)
      expect(described_class.new(peer, session).show_cocofolia_url?).to be(false)
      expect(described_class.new(admin, session).show_cocofolia_url?).to be(false)
      expect(described_class.new(gm, session).show_cocofolia_url?).to be(false)
      expect(described_class.new(nil, session).show_cocofolia_url?).to be(false)
    end
  end
end
