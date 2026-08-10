# 全員がプレイヤーになったため、権限としては保存しない。既存の行を落とす。
class RemoveStoredPlayerRoles < ActiveRecord::Migration[8.1]
  PLAYER = 2

  def up
    execute "DELETE FROM person_roles WHERE name = #{PLAYER}"
  end

  def down
    # 誰がプレイヤー行を持っていたかは復元できない。全員が持っていた状態に戻す。
    execute <<~SQL.squish
      INSERT INTO person_roles (person_id, name, created_at, updated_at)
      SELECT id, #{PLAYER}, NOW(), NOW() FROM people
    SQL
  end
end
