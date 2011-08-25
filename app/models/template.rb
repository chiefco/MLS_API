require 'builder'
class Template
  include Mongoid::Document
  include Mongoid::Timestamps
  default_scope :only=>[:_id,:name]
  field :name, :type => String
  field :description, :type => String
  validates_presence_of :name, :message=>"name - Required parameter missing", :code=>"2009"
  validates_uniqueness_of :name, :message => "name - name-already exist", :code=>"2009"
  #~ embeds_many :template_definitions
  #~ recursively_embeds_many :template_definitions
  references_many :template_definitions, :dependent => :destroy
  references_many :template_categories, :dependent => :destroy
  has_one :item
  default_scope :without=>[:created_at,:updated_at,:template_category_id]
end
