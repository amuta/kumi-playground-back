require 'rails_helper'

RSpec.describe KumiCompile do
  let(:simple_schema) do
    File.read(Rails.root.join("config/simple_schema.rb"))
  end

  describe ".call" do
    context "with valid schema" do
      it "returns success with compiled JavaScript" do
        result = KumiCompile.call(simple_schema)

        expect(result[:ok]).to eq(true)
        expect(result[:js_src]).to be_a(String)
        expect(result[:js_src]).not_to be_empty
      end

      it "returns schema_digest from analysis" do
        result = KumiCompile.call(simple_schema)

        expect(result[:ok]).to eq(true)
        expect(result[:schema_digest]).to be_present
      end

      it "generates valid JavaScript code" do
        result = KumiCompile.call(simple_schema)

        expect(result[:js_src]).to include("class")
      end
    end

    context "with invalid schema" do
      it "returns error with invalid syntax" do
        result = KumiCompile.call("invalid { syntax }")

        expect(result[:ok]).to eq(false)
        expect(result[:errors]).to be_present
      end

      it "returns error with empty string" do
        result = KumiCompile.call("")

        expect(result[:ok]).to eq(false)
        expect(result[:errors]).to be_present
      end

      it "returns error with malformed schema" do
        result = KumiCompile.call("schema do\n  this is not valid ruby\nend")

        expect(result[:ok]).to eq(false)
        expect(result[:errors]).to be_present
      end
    end

    context "with different schema structures" do
      it "compiles schema with simple input" do
        schema = <<~SCHEMA
          schema do
            input do
              string :name
            end
          end
        SCHEMA

        result = KumiCompile.call(schema)

        expect(result[:ok]).to eq(true)
        expect(result[:js_src]).to be_present
      end

      it "compiles schema with arrays" do
        schema = <<~SCHEMA
          schema do
            input do
              array :items do
                string :name
              end
            end
          end
        SCHEMA

        result = KumiCompile.call(schema)

        expect(result[:ok]).to eq(true)
        expect(result[:js_src]).to be_present
      end

      it "compiles schema with values and traits" do
        result = KumiCompile.call(simple_schema)

        expect(result[:ok]).to eq(true)
        expect(result[:js_src]).to be_present
      end
    end

    context "error handling" do
      it "logs errors on failure" do
        allow(Rails.logger).to receive(:error)

        KumiCompile.call("invalid")

        expect(Rails.logger).to have_received(:error)
      end

      it "returns error message as string" do
        result = KumiCompile.call("invalid")

        expect(result[:ok]).to eq(false)
        expect(result[:errors]).to be_a(String)
      end

      it "handles nil input gracefully" do
        result = KumiCompile.call(nil)

        expect(result[:ok]).to eq(false)
        expect(result[:errors]).to be_present
      end
    end

    context "consistency" do
      it "produces same output for same input" do
        result1 = KumiCompile.call(simple_schema)
        result2 = KumiCompile.call(simple_schema)

        expect(result1[:js_src]).to eq(result2[:js_src])
        expect(result1[:schema_digest]).to eq(result2[:schema_digest])
      end

      it "produces different output for different inputs" do
        schema1 = simple_schema
        schema2 = "schema do\n  input { string :other }\nend"

        result1 = KumiCompile.call(schema1)
        result2 = KumiCompile.call(schema2)

        expect(result1[:js_src]).not_to eq(result2[:js_src])
      end
    end

  end

  describe "integration with Kumi compiler" do
    it "uses Kumi::Frontends::Text.load" do
      expect(Kumi::Frontends::Text).to receive(:load).with(src: simple_schema).and_call_original

      KumiCompile.call(simple_schema)
    end

    it "uses Kumi::Analyzer.analyze!" do
      expect(Kumi::Analyzer).to receive(:analyze!).and_call_original

      KumiCompile.call(simple_schema)
    end

    it "requests side_tables in analysis" do
      expect(Kumi::Analyzer).to receive(:analyze!)
        .with(anything, side_tables: true)
        .and_call_original

      KumiCompile.call(simple_schema)
    end

    it "extracts JavaScript from codegen files" do
      result = KumiCompile.call(simple_schema)

      expect(result[:js_src]).to be_present
    end
  end
end
