class CreateMessages < ActiveRecord::Migration[6.0]
  def change
    create_table :messages do |t|
      t.text :content
      t.datetime :sent
      t.datetime :read
      t.references :author, null: false
      t.references :reciever, null: false

      t.timestamps
    end
    add_foreign_key :messages, :users, column: :author_id
    add_foreign_key :messages, :users, column: :reciever_id
  end
end
