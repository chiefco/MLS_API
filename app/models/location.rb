class Location
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name,:type=>String
  field :latitude,:type=>String
  field :longitude,:type=>String
  #~ field :item_id, :type => Integer
  has_one :item
end
