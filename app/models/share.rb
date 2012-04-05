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
  
  def share_folders
   self.folder
  end

  def save_activity(text, community_id, shared_id)
    @community = Community.find "#{community_id}"
    @community.activities.create(:action=>text, :shared_id => shared_id, :user_id=>self.user.nil?  ? 'nil' : self.user._id)
  end

  def self.update(attachment_id, new_attachment_id, user_id)
    Share.where(:shared_id => attachment_id, :user_id => user_id, :attachment_id => attachment_id).each{|a| a.update_attributes(:shared_id => new_attachment_id, :attachment_id => new_attachment_id, :user_id => user_id)}
  end
  
  def share_files(communities, files, folders, notes, current_user)
    user = current_user.email
    user_name = current_user.first_name
     community_users = []
     communities.each do |value|
          community_name = Community.find(value).name
          emails = CommunityUser.where(:community_id => value, :subscribe_email => true ).map(&:user).map(&:email) - [user]
          if notes.length == 0
            share_mail(user, user_name, value, community_name, emails, files, folders) unless emails.blank?
          else
            note_share_mail(user, user_name, value, community_name, emails, notes) unless emails.blank?
          end
     end
   end
   
   def share_mail(user, user_name, community_id, community_name, emails, files, folders)
     file_names = files*"," 
     folder_names = folders*"," 
     emails.each do |email|
       Invite.share_send_email(user, user_name, community_id, community_name, email, files.length, folders.length, file_names, folder_names).deliver
     end
   end
   
  # Public: Send mail to community users for meet sharing
   def note_share_mail(user, user_name, community_id, community_name, emails, notes)
     note_names = notes*"," 
     emails.each do |email|
       Invite.notes_share_send_email(user, user_name, community_id, community_name, email, notes.length,  note_names).deliver
     end
   end
   
   def self.shared_delete(community_id, count, item_name, current_user)
      current_user_email = current_user.email
      current_user_name = current_user.first_name
      community_name = Community.find(community_id).name
      emails = CommunityUser.where(:community_id => community_id, :subscribe_email => true).map(&:user).map(&:email) - [current_user_email]
      share_delete_notifications(current_user_email,current_user_name, community_id, community_name, emails, count, item_name)
    end
    
  def self.share_delete_notifications(current_user_email,current_user_name, community_id, community_name, emails, count, item_name)
    emails.each do |email|
       Invite.share_delete_email(current_user_email, current_user_name, community_id, community_name, email, count, item_name).deliver
     end
   end

 end