class RemoveWhatsappFromPlanConfigurations < ActiveRecord::Migration[7.2]
  def up
    PlanConfiguration.find_each do |config|
      next unless config.features.is_a?(Array)

      updated = config.features.reject { |f| f == "whatsapp_notifications" }
      config.update_columns(features: updated) if updated != config.features
    end
  end

  def down
    # No-op: restoring whatsapp_notifications would require knowing which plans had it
  end
end
