# 60 本規模なので事前生成せず、その場で組み立てる。生成物のための書き込み先が要らない。
class SitemapsController < ActionController::Base
  def show
    @scenarios = Scenario.order(:id)

    fresh_when etag: [ @scenarios.maximum(:updated_at), @scenarios.count ],
               last_modified: @scenarios.maximum(:updated_at),
               public: true
  end
end
