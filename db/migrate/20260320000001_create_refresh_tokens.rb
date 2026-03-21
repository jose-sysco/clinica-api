class CreateRefreshTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :refresh_tokens do |t|
      t.references :user,         null: false, foreign_key: true
      t.string     :token_digest, null: false
      t.datetime   :expires_at,   null: false
      t.datetime   :revoked_at
      t.timestamps
    end

    add_index :refresh_tokens, :token_digest, unique: true
    add_index :refresh_tokens, [:user_id, :revoked_at]
  end
end
