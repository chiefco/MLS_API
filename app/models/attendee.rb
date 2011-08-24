class Attendee
  include Mongoid::Document
  include Mongoid::Timestamps
  field :first_name,:type=>String
  field :last_name,:type=>String
  referenced_in :item
  validates_presence_of :first_name,:code=>"3010",:message=>"first_name - Blank Parameter"
  validates_presence_of :item_id,:code=>"3010",:message=>"first_name - Blank Parameter"
  #~ validates_uniqueness_of:item_id,:code=>:3010,:message=>"first_name - Blank Parameter"
end