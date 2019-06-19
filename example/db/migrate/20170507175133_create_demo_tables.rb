class CreateDemoTables < ActiveRecord::Migration[5.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.index :name, unique: true
      t.timestamps
    end

    create_table :posts do |t|
      t.references :category
      t.string :title, null: false
      t.index :title, unique: true
      t.string :body, null: false
      t.integer :views_count, null: false, default: 0
      t.integer :likes_count, null: false, default: 0
      t.integer :comments_count, null: false, default: 0
      t.datetime :published_at
      t.timestamps
    end
  end
end
