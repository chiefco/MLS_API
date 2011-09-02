class PageText
  include Mongoid::Document
  include Mongoid::Timestamps

  #fields
  field :position , type: Array
  field :content , type: String

  #associations
  embedded_in :page

end
