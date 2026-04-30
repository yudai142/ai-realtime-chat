class AddIndexesToConversations < ActiveRecord::Migration[7.2]
  def change
    # Chapter 9-2: Add indexes for sorting and searching
    add_index :conversations, :updated_at
    add_index :conversations, :title
  end
end
