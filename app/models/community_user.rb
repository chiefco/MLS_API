class CommunityUser
  include Mongoid::Document
  include Mongoid::Timestamps
  field :role_id,:type=>Boolean
  field :status,:type=>Boolean
end
