require 'rails_helper'

RSpec.describe "Api::KumiCompile", type: :request do
  let(:simple_schema) do
    File.read(Rails.root.join("config/simple_schema.rb"))
  end

  before do
    REDIS.flushdb
  end

  describe "POST /api/kumi/compile" do
    context "with valid schema" do
      it "compiles successfully and returns artifact details" do
        post "/api/kumi/compile", params: {
          schema_src: simple_schema
        }, as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["ok"]).to eq(true)
        expect(json["js_src"]).to be_a(String)
        expect(json["js_src"]).not_to be_empty
        expect(json["schema_hash"]).to be_present
        expect(json["artifact_url"]).to include("/api/kumi/artifacts/")
        expect(json["artifact_hash"]).to be_present
      end

      it "caches compiled JavaScript in Redis" do
        params = { schema_src: simple_schema }

        post "/api/kumi/compile", params: params, as: :json
        first_response = JSON.parse(response.body)

        expect(REDIS.keys("kumi:art:*").length).to eq(1)

        post "/api/kumi/compile", params: params, as: :json
        second_response = JSON.parse(response.body)

        expect(first_response["artifact_hash"]).to eq(second_response["artifact_hash"])
        expect(first_response["schema_hash"]).to eq(second_response["schema_hash"])
      end

      it "sets correct TTL on cached artifacts" do
        post "/api/kumi/compile", params: {
          schema_src: simple_schema
        }, as: :json

        cache_key = REDIS.keys("kumi:art:*").first
        ttl = REDIS.ttl(cache_key)

        expect(ttl).to be > 0
        expect(ttl).to be <= 30.days.to_i
      end
    end

    context "with missing parameters" do
      it "returns bad request when schema_src is missing" do
        post "/api/kumi/compile", params: {}, as: :json

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["ok"]).to eq(false)
        expect(json["errors"]).to be_present
      end
    end

    context "with invalid schema" do
      it "returns internal server error" do
        post "/api/kumi/compile", params: {
          schema_src: "invalid schema"
        }, as: :json

        expect(response).to have_http_status(:internal_server_error)
        json = JSON.parse(response.body)
        expect(json["ok"]).to eq(false)
        expect(json["errors"]).to be_present
      end
    end

    context "with different schemas" do
      it "generates different schema hashes for different schemas" do
        schema1 = simple_schema
        schema2 = "schema do\n  input { string :name }\nend"

        post "/api/kumi/compile", params: {
          schema_src: schema1
        }, as: :json
        hash1 = JSON.parse(response.body)["schema_hash"]

        post "/api/kumi/compile", params: {
          schema_src: schema2
        }, as: :json
        hash2 = JSON.parse(response.body)["schema_hash"]

        expect(hash1).not_to eq(hash2)
      end
    end
  end
end
