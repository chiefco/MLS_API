class CommunityUser
  include Mongoid::Document
  include Mongoid::Timestamps
  field :role_id,:type=>String,:default=>0
  field :status,:type=>Boolean,:default=>true
  field :user_id,:type=>String
  field :subscribe_email, :type => Boolean,:default=>true
  referenced_in :community
  belongs_to :user
  
  #scopes
  scope :undeleted,self.excludes(:status=>false)
  scope :by_user_id_and_community_id, lambda {|user_id, community_id| where(:community_id => community_id, :user_id => user_id)}
  scope :by_user_ids, lambda {|user_id| any_in(:user_id => user_id)}
  scope :by_community_ids, lambda{|community_id| any_in(:community_id => community_id)}
  scope :by_user_id, lambda{|user_id| where(:user_id => user_id)}
  # Get other users for ipad
  def self.other_users(user_id)
    users=where(:user_id =>user_id).map(&:community).select{|c|  c.status == true}.to_json(:only=>[:_id,:name,:description,:subscribe_email],:methods=>[:get_meets, :users_count,:members,:owner,:get_community_attachments,:subscribe]).parse
    return users
  end
  
  def self.shared_communities(user)
    where(:user_id => "#{user._id}").map(&:community).select{|c| c.user_id != user.id && c.status == true}.each {|c| c.unread_notification = c.unread_notifications(user)}
  end
  
end
