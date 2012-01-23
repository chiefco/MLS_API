class Invitation
  include Mongoid::Document
  include Mongoid::Timestamps
  field :email,:type=>String
  field :user_id,:type=>String
  field :invitation_token,:type=>String
  field :invited_at,:type=>Time
  field :invitation_accepted_at,:type=>Time
  referenced_in :community
  belongs_to :item
  referenced_in :user
  has_many :activities, as: :entity
  validates_presence_of :email,:message=>"email - Blank Parameter", :code=>3002
  #validates_uniqueness_of :email, :message=>"email - Already exist", :code=>3004, :allow_blank => true
  before_create :create_invitation_token
  
  #~ after_create :create_activity

  def create_activity(text,community_id, shared_id, user_id)
    save_activity(text,community_id, shared_id, user_id)
  end
  
  def create_invitation_token
    self.invitation_token=SecureRandom.base64(6).tr('+/=', 'xyz')    
    self.invited_at=Time.current
    create_invitation_token unless Invitation.where(:invitation_token=>self.invitation_token).first.nil?
  end
  
   def save_activity(text,user_id)
    self.activities.create(:action=>text,:user_id=>user_id)
  end
  
   def save_activity(text, community_id, shared_id, user_id)
    @community = Community.find "#{community_id}"
    @community.activities.create(:action=>text, :shared_id => shared_id, :user_id=>user_id)
  end
  
end
