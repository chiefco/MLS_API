class Share
  include Mongoid::Document
  include Mongoid::Timestamps
  field :status,:type=>Boolean
  referenced_in :community
  referenced_in :user
  referenced_in :item
  has_one :permission
end
