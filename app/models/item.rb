class Item
  include Mongoid::Document
  include Mongoid::Timestamps
  acts_as_api
  
  field :name, :type => String
  field :description, :type => String
  field :item_date, :type => Time
  field :status, :type => Boolean
  field :frequency_count, :type => Integer
  field :template_id, :type => String
  field :location_id, :type => String
  field :current_category_id, :type => String
  validates_presence_of :name,:message=>'name - Required parameter missing',:code=>2009
  validates_presence_of :template_id,:message=>'template_id - Blank Parameter',:code=>3025
  #~ references_and_referenced_in_many  :categories, :stored_as => :array, :inverse_of => :categories
  belongs_to  :template
  belongs_to  :location
  references_many :topics,:dependent => :destroy
  referenced_in :user
  referenced_in :template
  validates_presence_of :name,:message=>'name - Required parameter missing',:code=>2009
  validates_presence_of :template_id,:message=>'template_id - Required parameter missing',:code=>2011
  #~ validates :template_fields

  #~ def selected_items
    #~ {self.class.to_s.downcase=>self.to_json(:only=>[:id, :name])}.to_json
    #~ end

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
  
  #~ def selected_item_fields
    #~ self.to_json(:skip_instruct => true, :except =>[ :_id, :created_at, :updated_at ])
  #~ end
  
  def location_name
    self.location.nil? ? "nil" : self.location.name
  end
end
