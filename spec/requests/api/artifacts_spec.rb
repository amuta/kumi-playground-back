require 'rails_helper'

RSpec.describe "Api::Artifacts", type: :request do
  let(:simple_schema) do
    File.read(Rails.root.join("config/simple_schema.rb"))
  end

  before do
    REDIS.flushdb
  end

  describe "GET /api/kumi/artifacts/:schema_hash.js" do
    context "when artifact exists in cache" do
      let!(:compile_response) do
        post "/api/kumi/compile", params: {
          schema_src: simple_schema
        }, as: :json
        JSON.parse(response.body)
      end

      it "returns the cached JavaScript artifact" do
        schema_hash = compile_response["schema_hash"]

        get "/api/kumi/artifacts/#{schema_hash}.js"

        expect(response).to have_http_status(:success)
        expect(response.content_type).to eq("text/javascript")
        expect(response.body).to eq(compile_response["js_src"])
      end

      it "sets immutable cache headers" do
        schema_hash = compile_response["schema_hash"]

        get "/api/kumi/artifacts/#{schema_hash}.js"

        expect(response.headers["Cache-Control"]).to include("public")
        expect(response.headers["Cache-Control"]).to match(/max-age=\d+/)
        expect(response.headers["Cache-Control"]).to include("immutable")
      end

      it "sets inline disposition" do
        schema_hash = compile_response["schema_hash"]

        get "/api/kumi/artifacts/#{schema_hash}.js"

        expect(response.headers["Content-Disposition"]).to include("inline")
      end
    end

    context "when artifact does not exist in cache" do
      it "returns not found" do
        get "/api/kumi/artifacts/nonexistent_hash.js"

        expect(response).to have_http_status(:not_found)
      end
    end

    context "with different compiler versions" do
      it "uses version-specific cache keys" do
        post "/api/kumi/compile", params: {
          schema_src: simple_schema
        }, as: :json
        compile_response = JSON.parse(response.body)

        schema_hash = compile_response["schema_hash"]
        kver = ENV.fetch("KUMI_COMPILER_VERSION", "1")

        cache_key = "kumi:art:v#{kver}:#{schema_hash}"
        expect(REDIS.exists?(cache_key)).to eq(true)

        different_version_key = "kumi:art:v999:#{schema_hash}"
        expect(REDIS.exists?(different_version_key)).to eq(false)
      end
    end
  end
end
