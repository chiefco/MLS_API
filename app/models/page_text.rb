class PageText
  include Mongoid::Document
  include Mongoid::Timestamps
  
  #fields
  field :position , type: Array
  field :content , type: String
  field :page_id , type: String
  
  #associations
  referenced_in :page
  
  #validations 
  validates_presence_of :page_id, :message=>"page_id - Blank Parameter", :code=>3031
  
  
end
