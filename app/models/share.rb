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
 end

