class Community
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name,:type=>String
  field :description,:type=>String
  field :status,:type=>Boolean
  referenced_in :user
  references_many :invitations
  references_many :community_users
  validates_presence_of :name,:code=>3013,:message=>"name - Blank Parameter"
  scope :undeleted,self.excludes(:status=>true)
end
