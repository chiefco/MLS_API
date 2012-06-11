class CommunityUser
  include Mongoid::Document
  include Mongoid::Timestamps
  field :role_id,:type=>String,:default=>0
  field :status,:type=>Boolean,:default=>true
  field :user_id,:type=>String
  field :subscribe_email, :type => Boolean,:default=>true
  referenced_in :community
  belongs_to :user
  scope :undeleted,self.excludes(:status=>false)

  # Get other users for ipad
  def self.other_users(user_id)
    users=where(:user_id =>user_id).map(&:community).select{|c|  c.status == true}.to_json(:only=>[:_id,:name,:description,:subscribe_email],:methods=>[:get_meets, :users_count,:members,:owner,:get_community_attachments,:subscribe]).parse
    return users
  end
end
