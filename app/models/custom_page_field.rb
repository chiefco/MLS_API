class CustomPageField
  include Mongoid::Document
  include Mongoid::Timestamps
  field :field_name,:type=>String
  field :field_type,:type=>String
  referenced_in :custom_page
end
