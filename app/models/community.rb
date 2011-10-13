class Community
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name,:type=>String
  field :description,:type=>String
  field :status,:type=>Boolean,:default=>true
  referenced_in :user
  references_many :invitations
  references_many :shares
  references_many :community_users
  validates_presence_of :name,:code=>3013,:message=>"name - Blank Parameter"
  scope :undeleted,self.excludes(:status=>false)
  
  def active_user_ids
    community_users.where(:status=>true).map(&:user_id)
  end
  
  def stale_user_ids
    community_users.where(:status=>false).map(&:user_id)
  end
  
  def user_ids
    community_users.map(&:user_id)
  end
  
  def members
    User.find(active_user_ids)
  end
  
  def all_members
    User.find(user_ids)
  end
  
  def stale_members
    User.find(stale_user_ids)
  end
end
