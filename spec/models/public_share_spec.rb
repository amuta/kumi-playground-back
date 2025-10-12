require 'rails_helper'

RSpec.describe PublicShare, type: :model do
  describe "validations" do
    context "uid" do
      it "is required" do
        share = PublicShare.new(blob: "test data")
        expect(share).not_to be_valid
        expect(share.errors[:uid]).to include("can't be blank")
      end

      it "must be unique" do
        PublicShare.create!(uid: "PUB_test123", blob: "data1")
        duplicate = PublicShare.new(uid: "PUB_test123", blob: "data2")

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:uid]).to include("has already been taken")
      end

      it "allows different UIDs" do
        PublicShare.create!(uid: "PUB_test123", blob: "data1")
        different = PublicShare.new(uid: "PUB_test456", blob: "data2")

        expect(different).to be_valid
      end
    end

    context "blob" do
      it "is required" do
        share = PublicShare.new(uid: "PUB_test123")
        expect(share).not_to be_valid
        expect(share.errors[:blob]).to include("can't be blank")
      end

      it "accepts binary data" do
        binary_data = "\x00\x01\x02\x03".b
        share = PublicShare.new(uid: "PUB_test123", blob: binary_data)

        expect(share).to be_valid
      end

      it "accepts compressed data" do
        compressed = Brotli.deflate("test json data")
        share = PublicShare.new(uid: "PUB_test123", blob: compressed)

        expect(share).to be_valid
      end
    end
  end

  describe "database constraints" do
    it "enforces unique index on uid" do
      PublicShare.create!(uid: "PUB_unique", blob: "data1")

      expect {
        PublicShare.create!(uid: "PUB_unique", blob: "data2")
      }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "enforces not null constraint on uid" do
      share = PublicShare.new(uid: nil, blob: "data")

      expect {
        share.save!(validate: false)
      }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "enforces not null constraint on blob" do
      share = PublicShare.new(uid: "PUB_test", blob: nil)

      expect {
        share.save!(validate: false)
      }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end

  describe "creation" do
    it "stores and retrieves data correctly" do
      original_data = { test: "data", nested: { value: 123 } }.to_json
      compressed = Brotli.deflate(original_data)

      share = PublicShare.create!(uid: "PUB_test789", blob: compressed)
      retrieved = PublicShare.find(share.id)

      decompressed = Brotli.inflate(retrieved.blob)
      expect(decompressed).to eq(original_data)
    end

    it "generates timestamps" do
      share = PublicShare.create!(uid: "PUB_time", blob: "data")

      expect(share.created_at).to be_present
      expect(share.updated_at).to be_present
    end
  end

  describe "querying" do
    let!(:share1) { PublicShare.create!(uid: "PUB_abc123", blob: "data1") }
    let!(:share2) { PublicShare.create!(uid: "PUB_def456", blob: "data2") }

    it "finds by uid" do
      found = PublicShare.find_by(uid: "PUB_abc123")
      expect(found).to eq(share1)
    end

    it "returns nil for non-existent uid" do
      found = PublicShare.find_by(uid: "PUB_nonexistent")
      expect(found).to be_nil
    end

    it "raises error when using find_by! with non-existent uid" do
      expect {
        PublicShare.find_by!(uid: "PUB_nonexistent")
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "data integrity" do
    it "preserves binary data exactly" do
      binary_blob = (0..255).map(&:chr).join.b
      share = PublicShare.create!(uid: "PUB_binary", blob: binary_blob)

      retrieved = PublicShare.find(share.id)
      expect(retrieved.blob).to eq(binary_blob)
      expect(retrieved.blob.encoding).to eq(Encoding::ASCII_8BIT)
    end

    it "handles large compressed bundles" do
      large_data = { items: Array.new(1000) { |i| { id: i, data: "x" * 100 } } }.to_json
      compressed = Brotli.deflate(large_data)

      share = PublicShare.create!(uid: "PUB_large", blob: compressed)
      retrieved = PublicShare.find(share.id)

      decompressed = Brotli.inflate(retrieved.blob)
      expect(decompressed).to eq(large_data)
    end
  end
end
