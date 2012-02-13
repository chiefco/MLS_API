class Share
  include Mongoid::Document
  include Mongoid::Timestamps
  field :status,:type => Boolean,:default=>true
  field :shared_type, :type => String
  field :shared_id, :type => String
  referenced_in :community
  referenced_in :user
  belongs_to :item
  belongs_to :attachment
  belongs_to :permission
  has_many :activities, as: :entity
  
  #~ after_create :create_activity
  #~ after_update :update_activity
  
  
  def create_activity(text,community_id, shared_id)
    save_activity(text,community_id, shared_id)
  end
  
  #~ def update_activity
    #~ if self.status_changed? 
      #~ save_activity("SHARE_DELETED") 
    #~ else 
      #~ save_activity("SHARE_UPDATED")
    #~ end
  #~ end
  
  def create_permission(permission)
    access=Permission.where(:_id=>permission).first
    unless access.nil?
      self.update_attributes(:permission_id=>access._id)
    else
      default_permission
    end
  end
  
  def default_permission
    access=Permission.where(:role_name=>"View").first
    self.update_attributes(:permission_id=>access._id)
  end
  
  def user_details
    user.serializable_hash(:only=>[:_id,:first_name,:last_name])
  end
  
  def role
    permission=Permission.find(self.permission_id).role_name
  end
  
  def user_name
    User.find(self.user_id).first_name
  end
  
  def share_attachments
    self.attachment
  end
  
  def save_activity(text, community_id, shared_id)
    @community = Community.find "#{community_id}"
    @community.activities.create(:action=>text, :shared_id => shared_id, :user_id=>self.user.nil?  ? 'nil' : self.user._id)
  end
  
 end