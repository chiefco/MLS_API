class Subscription
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :product_id,:type=>String
  field :transaction_id,:type=>String
  field :receipt_details,:type=>Hash
  
  belongs_to :user
  
end
