class SitemapsController < ActionController::Base
  def show
    path = Rails.root.join("tmp/sitemaps/sitemap.xml")
    return head :not_found unless File.exist?(path)

    send_file path, type: "application/xml", disposition: "inline"
  end
end
