class Item
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, :type => String
  field :description, :type => String
  field :meet_date, :type => Time
  field :status, :type => Boolean
  field :frequency_count, :type => Integer
end
