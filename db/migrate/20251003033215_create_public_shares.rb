class CreatePublicShares < ActiveRecord::Migration[8.0]
  def change
    create_table :public_shares do |t|
      t.string :uid, null: false
      t.binary :blob, null: false

      t.timestamps
    end
    add_index :public_shares, :uid, unique: true
  end
end
