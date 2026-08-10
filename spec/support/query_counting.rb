module QueryCounting
  def queries_against(table)
    sqls = []
    callback = ->(_name, _start, _finish, _id, payload) do
      sqls << payload[:sql] if payload[:sql].include?(%(FROM "#{table}"))
    end
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
    sqls
  end
end

RSpec.configure do |config|
  config.include QueryCounting, type: :request
end
