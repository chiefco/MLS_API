class Industry
  include Mongoid::Document
  include Mongoid::Timestamps
  references_many :users
  field :name
end
