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
  
  def has_custom_page?
    has_value?(custom_page_definition)
  end
  
  def has_task_page?
    has_value?(task_page_definition)
  end

  def has_topic_page?
    has_value?(topic_page_definition)
  end
  
  def custom_page_definition
    template_definitions.excludes(:custom_page_id => nil).first
  end
  
  def task_page_definition
    template_definitions.where(:has_task_section=>true).first
  end

  def topic_page_definition
    template_definitions.where(:has_task_section=>true).first
  end
  
  def custom_page
    cus=custom_page_definition
    page={}
    cus.custom_page.custom_page_fields.collect{|f| page[f.field_name]=f.default} if cus
    page
  end
end
