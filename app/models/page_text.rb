class PageText
  include Mongoid::Document
  include Mongoid::Timestamps

  #fields
  field :position , type: String
  field :content , type: String

  #associations
  referenced_in :page

end
