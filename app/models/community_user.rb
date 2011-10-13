class CommunityUser
  include Mongoid::Document
  include Mongoid::Timestamps
  field :role_id,:type=>Boolean,:default=>false
  field :status,:type=>Boolean,:default=>false
  field :user_id,:type=>String
  referenced_in :community
end
