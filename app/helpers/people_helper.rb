module PeopleHelper
  # プレイヤーは保存しないが、全員が持つものとして必ず表示する。
  def person_role_labels(person)
    [ t("people.roles.player") ] + person.roles.map { |role| t("people.roles.#{role}") }
  end
end
