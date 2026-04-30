class AddUserToConversations < ActiveRecord::Migration[7.2]
  def up
    add_reference :conversations, :user, foreign_key: true, null: true

    # 既存データを暫定ユーザーに帰属
    user = User.find_by(email: "demo@example.com") || User.create!(email: "demo@example.com", password: "password", password_confirmation: "password")
    execute "UPDATE conversations SET user_id = #{user.id} WHERE user_id IS NULL;"

    change_column_null :conversations, :user_id, false
  end

  def down
    remove_reference :conversations, :user, foreign_key: true
  end
end
