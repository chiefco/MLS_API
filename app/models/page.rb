class Page
  include Mongoid::Document
  include Mongoid::Timestamps

  #fields
  field :page_order, type: Integer
  field :item_id , type: String

  #associations
  references_many :page_texts, :dependent=>:destroy
  belongs_to :item
  has_one :attachment, :as=>:attachable, :dependent=>:destroy
   
  #validations
  validates_presence_of :item_id, :message=>"item_id - Blank Parameter", :code=>3026
  
end
