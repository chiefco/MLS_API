class Item
  include Mongoid::Document
  include Mongoid::Timestamps
  acts_as_api
  
  field :name, :type => String
  field :description, :type => String
  field :meet_date, :type => Time
  field :status, :type => Boolean
  field :frequency_count, :type => Integer
  referenced_in :user
  validates_presence_of :name,:message=>'name - Required parameter missing',:code=>2009
  
  api_accessible :item_with_user do |template|
    template.add :name
    template.add :description
    template.add :meet_date
    template.add :_id
    template.add :frequency_count
  end
  
  api_accessible :item_detail do |template|
    template.add :name
    template.add :description
    template.add :meet_date
    template.add :_id
    template.add :frequency_count
  end
end
