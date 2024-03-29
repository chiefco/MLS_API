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
  belongs_to :folder
  belongs_to :permission
  has_many :activities, as: :entity
  
  #scopes 
  scope :attachment_shares, where(:shared_type => "Attachment", :status => true)
  scope :attachment_folders, where(:shared_type => "Folder", :status => true)
  
  #~ after_create :create_activity
  #~ after_update :update_activity


  # Create activity for share
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

  # Create permission
  def create_permission(permission)
    access=Permission.where(:_id=>permission).first
    unless access.nil?
      self.update_attributes(:permission_id=>access._id)
    else
      default_permission
    end
  end

  # Default permission
  def default_permission
    access=Permission.where(:role_name=>"View").first
    self.update_attributes(:permission_id=>access._id)
  end

  # Get user details of share
  def user_details
    user.serializable_hash(:only=>[:_id,:first_name,:last_name])
  end

  # Get role
  def role
    permission=Permission.find(self.permission_id).role_name
  end

  # Get user name for share
  def user_name
    User.find(self.user_id).first_name
  end

  # Get shared attachments for share
  def share_attachments
    self.attachment
  end
  
  # Get shared folders
  def share_folders
   self.folder
  end

  # Save activity
  def save_activity(text, community_id, shared_id)
    @community = Community.find "#{community_id}"
    @community.activities.create(:action=>text, :shared_id => shared_id, :user_id=>self.user.nil?  ? 'nil' : self.user._id)
  end

  # Update share
  def self.update(attachment_id, new_attachment_id, user_id)
    Share.where(:shared_id => attachment_id, :user_id => user_id, :attachment_id => attachment_id).each{|a| a.update_attributes(:shared_id => new_attachment_id, :attachment_id => new_attachment_id, :user_id => user_id)}
  end
  
  # Share files notification
  def share_files(communities, files, folders, notes, notes_id, current_user)
    user = current_user.email
    user_name = current_user.first_name
     community_users = []
     communities.each do |value|
          community_name = Community.find(value).name
          emails = CommunityUser.where(:community_id => value, :subscribe_email => true ).map(&:user).map(&:email) - [user]
          if notes.length == 0
            share_mail(user, user_name, value, community_name, emails, files, folders) unless emails.blank?
          else
            note_share_mail(user, user_name, value, community_name, emails, notes, notes_id) unless emails.blank?
          end
     end
   end
   
   # Send mail to community users  for  attachments sharing
   def share_mail(user, user_name, community_id, community_name, emails, files, folders)
     file_names = files*"," 
     folder_names = folders*"," 
     emails.each do |email|
       Invite.share_send_email(user, user_name, community_id, community_name, email, files.length, folders.length, file_names, folder_names).deliver
     end
   end
   
  # Send mail to community users for meet sharing
   def note_share_mail(user, user_name, community_id, community_name, emails, notes, notes_id)
     note_names = notes*"," 
     emails.each do |email|
       Invite.notes_share_send_email(user, user_name, community_id, community_name, email, notes.length,  note_names, notes_id).deliver
     end
   end
   
   # Send mail to community users  for  delete shares
   def self.shared_delete(community_id, count, item_name, current_user)
      current_user_email = current_user.email
      current_user_name = current_user.first_name
      community_name = Community.find(community_id).name
      emails = CommunityUser.where(:community_id => community_id, :subscribe_email => true).map(&:user).map(&:email) - [current_user_email]
      share_delete_notifications(current_user_email,current_user_name, community_id, community_name, emails, count, item_name)
    end
    
  # Shae delete notifications
  def self.share_delete_notifications(current_user_email,current_user_name, community_id, community_name, emails, count, item_name)
    emails.each do |email|
       Invite.share_delete_email(current_user_email, current_user_name, community_id, community_name, email, count, item_name).deliver
     end
   end

 end