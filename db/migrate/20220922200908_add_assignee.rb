class AddAssignee < ActiveRecord::Migration[7.0]
  def change
    change_table :notification_settings, bulk: true do |t|
      t.column :assignee, :boolean, default: false, null: false
      t.column :accountable, :boolean, default: false, null: false
    end

    NotificationSetting.where(involved: true).update_all(assignee: true, accountable: true)
  end
end
