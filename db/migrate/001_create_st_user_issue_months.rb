class CreateStUserIssueMonths < ActiveRecord::Migration
  def self.up
    create_table :st_user_issue_months do |t|
      t.column :user_id, :integer
      t.column :issue_id, :integer
      t.column :month, :string
      t.column :position, :integer
    end
  end

  def self.down
    drop_table :st_user_issue_months
  end
end
