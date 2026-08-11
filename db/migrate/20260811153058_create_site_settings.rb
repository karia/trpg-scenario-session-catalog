class CreateSiteSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :site_settings do |t|
      t.string :google_analytics_measurement_id, null: false, default: ""

      t.timestamps
    end
  end
end
