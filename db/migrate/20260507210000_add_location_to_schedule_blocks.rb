class AddLocationToScheduleBlocks < ActiveRecord::Migration[7.2]
  def change
    add_reference :schedule_blocks, :location, null: true, foreign_key: true
  end
end
