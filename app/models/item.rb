class Item
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, :type => String
  field :description, :type => String
  field :meet_date, :type => Time
  field :status, :type => Boolean
  field :frequency_count, :type => Integer
  
  validates_presence_of :name,:message=>'name - Required parameter missing',:code=>2009

end
