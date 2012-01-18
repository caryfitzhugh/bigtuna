class AddAnyFlagToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :build_any, :boolean, :default => false
  end

  def self.down
    remove_column :projects, :build_any
  end
end
