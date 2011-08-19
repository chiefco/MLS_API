require 'builder'
class Template
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, :type => String
  field :description, :type => String
  validates_presence_of :name, :message=>"name - Required parameter missing", :code=>"2009"
  validates_uniqueness_of :name, :message => "name - name-already exist", :code=>"2009"
  #~ embeds_many :template_definitions
  #~ recursively_embeds_many :template_definitions
  references_many :template_definitions, :dependent => :destroy
  has_one :item
end
