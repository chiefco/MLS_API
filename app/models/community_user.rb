class CommunityUser
  include Mongoid::Document
  include Mongoid::Timestamps
  field :role_id,:type=>String,:default=>0
  field :status,:type=>Boolean,:default=>true
  field :user_id,:type=>String
  referenced_in :community
  belongs_to :user
end
