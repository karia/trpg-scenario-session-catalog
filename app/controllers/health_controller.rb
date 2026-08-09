# Kubernetes の probe が User-Agent を持たないため allow_browser を通さない。
class HealthController < ActionController::Base
  # 接続は遅延生成されるため active? では判定できない。verify! で実際につなぐ。
  def show
    ActiveRecord::Base.connection.verify!
    head :ok
  rescue StandardError
    head :service_unavailable
  end
end
