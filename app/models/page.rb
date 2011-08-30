class Page
  include Mongoid::Document
  include Mongoid::Timestamps

<<<<<<< HEAD
  #fields
  field :page_order, type: Integer
  field :item_id , type: String

  #associations
  references_many :page_texts, :dependent=>:destroy
  belongs_to :item
  has_one :attachment, :as=>:attachable, :dependent=>:destroy
   
  #validations
  validates_presence_of :item_id, :message=>"item_id - Blank Parameter", :code=>3026
  
=======

  #call backs
  before_save :generate_link

  #fields
  field :page_order, type: Integer
  field :item_id , type: String
  field :file_link , type: String

  #associations
  references_many :page_texts, :dependent=>:destroy
  referenced_in :item
  references_one :attachment, :as=>:attachable, :dependent=>:destroy

  #validations
  validates_presence_of :item_id, :message=>"item_id - Blank Parameter", :code=>3026
  validates_presence_of :file, :message=>"The file was not correctly uploaded", :code=>6001

  private

  def generate_link
    self.file_link = self.file.url
  end

>>>>>>> d88c5742df9178c0ef03c98d47832c88da7890a1
end
