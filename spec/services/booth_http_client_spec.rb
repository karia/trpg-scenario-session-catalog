require "rails_helper"

RSpec.describe BoothHttpClient do
  subject(:client) { described_class.new }

  def response(type, body:, content_type:, location: nil)
    code, message = type == Net::HTTPFound ? [ "302", "Found" ] : [ "200", "OK" ]
    result = type.new("1.1", code, message)
    result.body = body
    result.instance_variable_set(:@read, true)
    result["content-type"] = content_type
    result["location"] = location if location
    result
  end

  it "refuses a page outside BOOTH before making a request" do
    allow(client).to receive(:request)

    expect { client.get("https://example.com/items/1", kind: :page) }
      .to raise_error(described_class::Error, "unsupported URL")
    expect(client).not_to have_received(:request)
  end

  it "refuses an og:image outside BOOTH's image host" do
    allow(client).to receive(:request)

    expect { client.get("https://example.com/image.png", kind: :image) }
      .to raise_error(described_class::Error, "unsupported URL")
  end

  it "follows redirects only through allowed BOOTH URLs" do
    redirect = response(Net::HTTPFound, body: "", content_type: "text/html", location: "https://shop.booth.pm/items/1")
    success = response(Net::HTTPOK, body: "<html></html>", content_type: "text/html")
    allow(client).to receive(:request).and_return(redirect, success)

    result = client.get("https://booth.pm/items/1", kind: :page)

    expect(result.body).to eq("<html></html>")
  end

  it "rejects a non-image response from the image host" do
    allow(client).to receive(:request).and_return(
      response(Net::HTTPOK, body: "not an image", content_type: "text/html")
    )

    expect { client.get("https://booth.pximg.net/image.png", kind: :image) }
      .to raise_error(described_class::Error, "unexpected content type")
  end
end
