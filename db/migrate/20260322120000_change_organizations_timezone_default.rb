class ChangeOrganizationsTimezoneDefault < ActiveRecord::Migration[7.2]
  def up
    change_column_default :organizations, :timezone, from: "UTC", to: "America/Guatemala"

    # Actualizar organizaciones existentes que aún tienen el default "UTC"
    Organization.where(timezone: "UTC").update_all(timezone: "America/Guatemala")
  end

  def down
    change_column_default :organizations, :timezone, from: "America/Guatemala", to: "UTC"
  end
end
