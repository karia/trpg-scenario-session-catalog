require "rails_helper"

RSpec.describe GoogleTokenRevoker do
  it "posts the refresh token to Google's revoke endpoint" do
    response = Net::HTTPOK.new("1.1", "200", "OK")
    http = instance_double(Net::HTTP, request: response)
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)

    described_class.revoke("refresh token")

    expect(http).to have_received(:use_ssl=).with(true)
    expect(http).to have_received(:request) do |request|
      expect(request).to be_a(Net::HTTP::Post)
      expect(request.path).to eq("/revoke")
      expect(URI.decode_www_form(request.body)).to contain_exactly([ "token", "refresh token" ])
    end
  end

  it "raises when Google refuses the revoke" do
    response = Net::HTTPBadRequest.new("1.1", "400", "Bad Request")
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response)

    expect { described_class.revoke("bad-token") }.to raise_error(described_class::Error)
  end

  it "wraps connection failures" do
    allow_any_instance_of(Net::HTTP).to receive(:request).and_raise(Errno::ECONNREFUSED)

    expect { described_class.revoke("refresh-token") }
      .to raise_error(described_class::Error, "Google token revoke failed")
  end
end
