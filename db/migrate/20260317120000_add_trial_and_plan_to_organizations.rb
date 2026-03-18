class AddTrialAndPlanToOrganizations < ActiveRecord::Migration[7.2]
  def change
    add_column :organizations, :plan, :integer, default: 0, null: false
    add_column :organizations, :trial_ends_at, :datetime
    add_column :organizations, :suspended_at, :datetime
  end
end
