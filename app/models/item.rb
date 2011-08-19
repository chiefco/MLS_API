class Item
  include Mongoid::Document
  include Mongoid::Timestamps
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
  def selected_items
    {self.class.to_s.downcase=>self.to_json(:only=>[:id, :name])}.to_json
    end
end
