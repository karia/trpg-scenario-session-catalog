# Kubernetes の probe が User-Agent を持たないため allow_browser を通さない。
class HealthController < ActionController::Base
  def show
    ActiveRecord::Base.connection.active? || raise(ActiveRecord::ConnectionNotEstablished)
    head :ok
  rescue StandardError
    head :service_unavailable
  end
end
