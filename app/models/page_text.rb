class PageText
  include Mongoid::Document
  include Mongoid::Timestamps

  #fields
  field :position , type: Array
  field :content , type: String
<<<<<<< HEAD
   
=======
  field :page_id , type: String

>>>>>>> d88c5742df9178c0ef03c98d47832c88da7890a1
  #associations
  referenced_in :page

  #validations
  validates_presence_of :page_id, :message=>"page_id - Blank Parameter", :code=>3031


end
