# 設定が欠けたまま本番が起動すると、ヘルスチェックが通ったあとで実害が出る。起動時に落とす。
# イメージビルド中の assets:precompile は接続情報を持たないため対象外にする。
if Rails.env.production? && ENV["SECRET_KEY_BASE_DUMMY"].blank?
  required = %w[
    SECRET_KEY_BASE
    DATABASE_HOST DATABASE_USERNAME DATABASE_PASSWORD DATABASE_NAME
    S3_ENDPOINT S3_ACCESS_KEY_ID S3_SECRET_ACCESS_KEY S3_BUCKET
  ]
  missing = required.reject { |key| ENV[key].present? }

  raise "Missing required environment variables: #{missing.join(", ")}" if missing.any?
end
