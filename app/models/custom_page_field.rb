class CustomPageField
  include Mongoid::Document
  include Mongoid::Timestamps
  field :field_name,:type=>String
  field :field_type,:type=>String
  referenced_in :custom_page
  validates_presence_of :field_name,:code=>"3067",:message=> "field_name - Blank Parameter"
  validates_presence_of :field_type,:code=>"3068",:message=>"field_type - Blank Parameter"
  validates_presence_of :custom_page_id,:code=>"3069",:message=>"custom_page_id - Blank Parameter"
end
