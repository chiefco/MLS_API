class Topic
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, :type => String
  field :status, :type => Integer
  referenced_in :item  
  validates_presence_of :item_id, :message=>"item_id - Blank Parameter", :code=>"3026",:on=>:create
  validates_presence_of :name, :message=>"name - Required parameter missing", :code=>"2009"
  has_many :activities, as: :activity, :dependent=>:destroy
  def get_item
    item=self.item.to_json(:only=>[:_id,:name,:description])
    return item
  end
end
