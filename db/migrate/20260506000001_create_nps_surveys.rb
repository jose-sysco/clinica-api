class CreateNpsSurveys < ActiveRecord::Migration[7.2]
  def change
    create_table :nps_surveys do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :appointment,  null: false, foreign_key: true, index: { unique: true }
      t.string  :token,        null: false
      t.integer :score
      t.text    :comment
      t.datetime :submitted_at
      t.timestamps
    end

    add_index :nps_surveys, :token, unique: true
  end
end
