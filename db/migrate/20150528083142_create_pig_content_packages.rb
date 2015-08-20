class CreatePigContentPackages < ActiveRecord::Migration

  def change
    create_table :pig_content_packages do |t|
      t.string :slug
      t.string :name
      t.belongs_to :content_type
      t.integer :position, default: 0
      t.integer :parent_id, null: true, index: true
      t.integer :lft, null: false, index: true
      t.integer :rgt, null: false, index: true
      t.belongs_to :author
      t.belongs_to :requested_by
      t.string :status, default: 'draft'
      t.boolean :logged_in_only, default: false
      t.boolean :hide_from_robots, default: false
      t.text :notes
      t.date :due_date
      t.integer :review_frequency
      t.date :next_review
      t.date :publish_at
      t.date :published_at
      t.datetime :deleted_at
      t.string :meta_title
      t.text :meta_description
      t.string :meta_keywords
      t.string :meta_image_uid
      t.string :meta_image_name
      t.json :json_content, null: false, default: '{}'
      t.integer :depth, :null => false, :default => 0
      t.integer :children_count, :null => false, :default => 0
      t.timestamps
    end
    add_index :pig_content_packages, :slug
  end

end
