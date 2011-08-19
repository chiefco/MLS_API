class Item
  include Mongoid::Document
  include Mongoid::Timestamps
  acts_as_api
  
  field :name, :type => String
  field :description, :type => String
  field :item_date, :type => Time
  field :status, :type => Boolean
  field :frequency_count, :type => Integer
<<<<<<< HEAD:app/models/item.rb
  field :template_id, :type => Integer
  field :location_id, :type => Integer
  field :current_category_id, :type => Integer
  validates_presence_of :name,:message=>'name - Required parameter missing',:code=>2009
  validates_presence_of :template_id,:message=>'template_id - Blank Parameter',:code=>3025
  belongs_to  :template
  belongs_to  :location
=======
  referenced_in :user
  referenced_in :template
  validates_presence_of :name,:message=>'name - Required parameter missing',:code=>2009
  validates_presence_of :template_id,:message=>'template_id - Required parameter missing',:code=>2011
  #~ validates :template_fields

  def template_fields
    true
  end
  
  api_accessible :item_with_user do |t|
    t.add :name
    t.add :description
    t.add :meet_date
    t.add :_id
    t.add :frequency_count
  end
  
  api_accessible :item_detail,:extend=>:item_with_user do |t|
    t.add 'user'
  end
>>>>>>> master:app/models/item.rb
end
