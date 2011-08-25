class CustomPage
  include Mongoid::Document
  include Mongoid::Timestamps
  field :page_data,:type=>String
  #~ field :template_definition_id,:type=>Integer
  has_one :template_definition
  #~ referenced_in :template_definition
  references_many :custom_page_fields, :dependent => :destroy
end
