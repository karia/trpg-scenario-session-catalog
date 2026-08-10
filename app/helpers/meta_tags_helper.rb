module MetaTagsHelper
  SITE_NAME = "卓の記録".freeze
  SITE_DESCRIPTION = "遊んだ TRPG シナリオの一覧。システム、人数、目安時間から選べます。".freeze

  def default_meta_tags
    {
      site: SITE_NAME,
      reverse: true,
      separator: "|",
      description: SITE_DESCRIPTION,
      og: {
        site_name: SITE_NAME,
        type: "website",
        url: request.original_url,
        locale: "ja_JP"
      },
      twitter: { card: "summary_large_image" }
    }
  end
end
