# 正規表現の前方一致だと改行以降に別スキームを潜ませられるため、URI として解釈して確かめる。
class HttpUrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    uri = URI.parse(value)
    record.errors.add(attribute, :invalid) unless uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    record.errors.add(attribute, :invalid)
  end
end
