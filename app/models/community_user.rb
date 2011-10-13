class CommunityUser
  include Mongoid::Document
  include Mongoid::Timestamps
  field :role_id,:type=>String
  field :status,:type=>Boolean,:default=>true
  field :user_id,:type=>String
  referenced_in :community
end
