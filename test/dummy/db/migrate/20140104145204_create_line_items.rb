class CreateLineItems < ActiveRecord::Migration[7.1]
  def change
    create_table :line_items do |t|
      t.integer :quantity
      t.integer :product_id
      t.integer :invoice_id

      t.timestamps
    end
  end
end
