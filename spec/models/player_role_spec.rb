require "rails_helper"

# 全員がプレイヤーなので、権限として保存しない。行で持つと画面外で作った Person に
# 付け忘れる余地が残る。Person が存在することがそのままプレイヤーであることを表す。
RSpec.describe "The player role" do
  it "is true for anyone, including a person with no stored roles" do
    expect(create(:person)).to be_player
  end

  it "is true for an administrator" do
    expect(create(:person, roles: %w[admin])).to be_player
  end

  it "is not something the roles list can grant or withhold" do
    person = create(:person, roles: %w[admin])

    expect(person.roles).to eq([ "admin" ])
    expect(person).to be_player
  end

  it "cannot be stored, so it cannot drift out of sync" do
    expect(PersonRole::ROLES.keys).to match_array(%i[admin gm])
    expect(build(:person).person_roles.build(name: "player")).not_to be_valid
  end

  it "is ignored when submitted, rather than failing the update" do
    person = create(:person, roles: %w[gm])

    person.update!(roles: %w[gm player])

    expect(person.reload.roles).to eq([ "gm" ])
    expect(person).to be_player
  end

  # player だけを落とす。未知の値まで黙って捨てると、綴り間違いが成功して見える。
  it "still rejects a role name that is not known at all" do
    person = create(:person)

    expect(person.update(roles: %w[owner])).to be(false)
    expect(person.reload.roles).to be_empty
  end

  # 未知の整数が残った行があっても、翻訳キーの引き当てでロケール全体を出さない。
  it "ignores a stored role whose value is no longer known" do
    person = create(:person, roles: %w[gm])
    ActiveRecord::Base.connection.execute(
      "INSERT INTO person_roles (person_id, name, created_at, updated_at) VALUES (#{person.id}, 99, NOW(), NOW())"
    )

    expect(person.reload.roles).to eq([ "gm" ])
  end

  it "grants nothing beyond what a person with no roles can do" do
    plain = create(:person)

    expect(ScenarioPolicy.new(plain, Scenario.new).update?).to be_falsey
    expect(PlaySessionPolicy.new(plain, PlaySession.new).manage?).to be_falsey
    expect(PersonPolicy.new(plain, Person.new).manage?).to be_falsey
  end

  it "still lets a member see the signed-in area" do
    plain = create(:person)

    expect(PlaySessionPolicy.new(plain, PlaySession.new).index?).to be(true)
    expect(PersonPolicy.new(plain, Person.new).show?).to be(true)
  end
end
