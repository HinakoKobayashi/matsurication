class AddConfirmedToNotification < ActiveRecord::Migration[6.1]
  def change
    add_column :notifications, :confirmed, :boolean, default: false
  end
end
