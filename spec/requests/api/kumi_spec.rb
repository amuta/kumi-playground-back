require 'rails_helper'

RSpec.describe "Api::Kumi", type: :request do
  describe "POST /api/kumi/compile" do
    let(:simple_schema) do
      File.read(Rails.root.join("config/simple_schema.rb"))
    end

    context "with valid schema" do
      it "compiles successfully and returns JavaScript code" do
        post "/api/kumi/compile", params: { schema_src: simple_schema }, as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["ok"]).to eq(true)
        expect(json["js_src"]).to be_a(String)
        expect(json["js_src"]).not_to be_empty
      end
    end

    context "with missing schema_src parameter" do
      it "returns bad request error" do
        post "/api/kumi/compile", params: {}, as: :json

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["ok"]).to eq(false)
        expect(json["errors"]).to be_present
      end
    end

    context "with invalid schema" do
      it "returns internal server error" do
        post "/api/kumi/compile", params: { schema_src: "invalid schema" }, as: :json

        expect(response).to have_http_status(:internal_server_error)
        json = JSON.parse(response.body)
        expect(json["ok"]).to eq(false)
      end
    end
  end
end
