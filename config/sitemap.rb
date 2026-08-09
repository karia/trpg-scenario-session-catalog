SitemapGenerator::Sitemap.default_host = "https://#{ENV.fetch("APP_HOST", "trpg-catalog.side2.net")}"
SitemapGenerator::Sitemap.public_path = "tmp/sitemaps/"
SitemapGenerator::Sitemap.sitemaps_path = ""
SitemapGenerator::Sitemap.compress = false

SitemapGenerator::Sitemap.create do
  # 公開エリアだけを載せる。ログインが要る画面は検索対象にしない。
  Scenario.find_each do |scenario|
    add scenario_path(scenario), lastmod: scenario.updated_at, changefreq: "monthly"
  end
end
