require 'rails_helper'

RSpec.describe "Api::Shares", type: :request do
  let(:bundle_data) do
    {
      v: 1,
      format: "grid2d@1",
      schema_src: "schema { input { string :name } }",
      schema_hash: "abc123",
      compiler_version: "1",
      artifact_hash: "def456",
      js_src: "console.log('test')",
      metadata: { palette: { "0" => "#fff", "1" => "#000" }, cellSize: 10 }
    }
  end

  before do
    REDIS.flushdb
  end

  describe "POST /api/share/ephemeral" do
    context "with valid bundle data" do
      it "creates an ephemeral share and returns URL" do
        post "/api/share/ephemeral", params: bundle_data.to_json,
          headers: { "Content-Type" => "application/json" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["url"]).to match(%r{/api/s/[A-Za-z0-9_-]+})
      end

      it "stores compressed data in Redis with TTL" do
        post "/api/share/ephemeral", params: bundle_data.to_json,
          headers: { "Content-Type" => "application/json" }

        share_id = JSON.parse(response.body)["url"].split("/").last
        key = "kumi:share:#{share_id}"

        expect(REDIS.exists?(key)).to eq(true)
        expect(REDIS.ttl(key)).to be > 0
        expect(REDIS.ttl(key)).to be <= 7.days.to_i
      end

      it "compresses data using Brotli" do
        post "/api/share/ephemeral", params: bundle_data.to_json,
          headers: { "Content-Type" => "application/json" }

        share_id = JSON.parse(response.body)["url"].split("/").last
        key = "kumi:share:#{share_id}"

        compressed_data = REDIS.get(key)
        decompressed_data = Brotli.inflate(compressed_data)

        expect(JSON.parse(decompressed_data)).to eq(JSON.parse(bundle_data.to_json))
      end
    end

    context "with params hash instead of raw post" do
      it "creates share from params" do
        post "/api/share/ephemeral", params: bundle_data, as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["url"]).to be_present
      end
    end
  end

  describe "GET /api/s/:id" do
    context "when ephemeral share exists" do
      let!(:share_url) do
        post "/api/share/ephemeral", params: bundle_data.to_json,
          headers: { "Content-Type" => "application/json" }
        JSON.parse(response.body)["url"]
      end

      it "returns the decompressed bundle data" do
        get share_url

        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/json")

        returned_data = JSON.parse(response.body)
        expected_data = JSON.parse(bundle_data.to_json)

        expect(returned_data).to eq(expected_data)
      end

      it "sets correct content disposition" do
        get share_url

        expect(response.headers["Content-Disposition"]).to include("kumi-bundle.json")
      end
    end

    context "when ephemeral share does not exist" do
      it "returns not found" do
        get "/api/s/nonexistent"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when ephemeral share has expired" do
      it "returns not found" do
        post "/api/share/ephemeral", params: bundle_data.to_json,
          headers: { "Content-Type" => "application/json" }
        share_url = JSON.parse(response.body)["url"]

        share_id = share_url.split("/").last
        REDIS.del("kumi:share:#{share_id}")

        get share_url

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /api/share/public" do
    context "with valid bundle data" do
      it "creates a public share and returns URL" do
        post "/api/share/public", params: bundle_data.to_json,
          headers: { "Content-Type" => "application/json" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["url"]).to match(%r{/api/p/PUB_[A-Za-z0-9]+})
      end

      it "persists the share in database" do
        expect {
          post "/api/share/public", params: bundle_data.to_json,
            headers: { "Content-Type" => "application/json" }
        }.to change(PublicShare, :count).by(1)
      end

      it "stores compressed data using Brotli" do
        post "/api/share/public", params: bundle_data.to_json,
          headers: { "Content-Type" => "application/json" }

        share_uid = JSON.parse(response.body)["url"].split("/").last
        public_share = PublicShare.find_by(uid: share_uid)

        decompressed_data = Brotli.inflate(public_share.blob)
        expect(JSON.parse(decompressed_data)).to eq(JSON.parse(bundle_data.to_json))
      end

      it "generates unique UIDs" do
        post "/api/share/public", params: bundle_data.to_json,
          headers: { "Content-Type" => "application/json" }
        uid1 = JSON.parse(response.body)["url"].split("/").last

        post "/api/share/public", params: bundle_data.to_json,
          headers: { "Content-Type" => "application/json" }
        uid2 = JSON.parse(response.body)["url"].split("/").last

        expect(uid1).not_to eq(uid2)
      end
    end
  end

  describe "GET /api/p/:uid" do
    context "when public share exists" do
      let!(:share_url) do
        post "/api/share/public", params: bundle_data.to_json,
          headers: { "Content-Type" => "application/json" }
        JSON.parse(response.body)["url"]
      end

      it "returns the decompressed bundle data" do
        get share_url

        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("application/json")

        returned_data = JSON.parse(response.body)
        expected_data = JSON.parse(bundle_data.to_json)

        expect(returned_data).to eq(expected_data)
      end

      it "sets correct content disposition" do
        get share_url

        expect(response.headers["Content-Disposition"]).to include("kumi-bundle.json")
      end
    end

    context "when public share does not exist" do
      it "returns not found" do
        get "/api/p/PUB_nonexistent"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "data compression" do
    it "reduces data size with Brotli compression" do
      original_size = bundle_data.to_json.bytesize
      compressed_data = Brotli.deflate(bundle_data.to_json)
      compressed_size = compressed_data.bytesize

      expect(compressed_size).to be < original_size
    end

    it "correctly roundtrips data through compression" do
      original_json = bundle_data.to_json
      compressed = Brotli.deflate(original_json)
      decompressed = Brotli.inflate(compressed)

      expect(decompressed).to eq(original_json)
    end
  end
end
