class CommunityInvitee
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :email, :type => String
  field :invited_count, :type => Integer, :default => 1
  referenced_in :community
end
