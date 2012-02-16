class CommunityInvitee
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :email, :type => String
  referenced_in :community
end
