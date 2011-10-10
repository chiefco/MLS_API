class Topic
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, :type => String
  field :status, :type => Integer,:default=>1
  referenced_in :item
  validates_presence_of :item_id, :message=>"item_id - Blank Parameter", :code=>"3026",:on=>:create
  validates_presence_of :name, :message=>"name - Required parameter missing", :code=>"2009"
  validates :name ,:length => { :minimum => 3 ,:maximum =>20,:message=>"name-invalid length",:code=>3073,:allow_blank=>true}
  validates_inclusion_of :status, :in=>[1,2,3], :message=>"invalid-status", :code=>3072
  has_many :comments, as: :commentable
  has_many :activities, as: :activity, :dependent=>:destroy
  def topic_item
    item=self.item.to_json(:only=>[:_id,:name,:description]).parse
  end
end
