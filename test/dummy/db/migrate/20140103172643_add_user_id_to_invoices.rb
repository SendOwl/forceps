class AddUserIdToInvoices < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :user_id, :integer
  end
end
