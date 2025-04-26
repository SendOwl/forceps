class AddNumberToInvoices < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :number, :integer
  end
end
