class Community
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, :type => String
  field :description, :type => String
  field :status, :type => Boolean, :default => true
  field :invitees, :type => Array
  field :unread_notification, :type => Integer
  referenced_in :user
  references_many :invitations
  references_many :shares
  references_many :community_users
  references_many :community_invitees
  has_many :activities, as: :entity
  has_many :attachments, :dependent => :destroy  
  has_many :folders, :dependent => :destroy   
  has_many :notifications, as: :notifier, :dependent=>:destroy  

  validates_presence_of :name,:code=>3013,:message=>"name - Blank Parameter"
  scope :undeleted,self.excludes(:status=>false)

  after_create :create_activity
  after_update :update_activity

  def create_activity
    save_activity("COMMUNITY_CREATED")
  end
  
  def update_activity
    if self.status_changed?
      save_activity("COMMUNITY_DELETED")
    else
      save_activity("COMMUNITY_UPDATED")
    end
  end

  def active_users
    community_users.where(:status=>true)
  end

  def active_user_ids
    active_users.map(&:user_id)
  end

  def stale_user_ids
    community_users.where(:status=>false).map(&:user_id)
  end

  def user_ids
    community_users.map(&:user_id)
  end

  def members
    value=[]
    active_users.collect{|cu| value<<cu.user.serializable_hash(:methods=>:id).merge({:role=>cu.role_id})}
    value
  end

  def all_members
    User.find(user_ids)
  end

  def stale_members
    User.find(stale_user_ids)
  end

  def self.get_communities(user)
    @community=[]
    @community_values={}
    user.communities.undeleted.each do |f|
      @community<<f._id.to_s
      @community_values=@community_values.merge({"#{f.id}"=>{:name=>"#{f.name}",:id=>"#{f._id}",:users_count => "#{f.users_count}",:members=>f.members,:subscribe=>f.community_users.where(:user_id=>user._id).first.subscribe_email.to_s}})
    end
    return {:community_arrays=>@community,:community_hashes=>@community_values}
  end

  def community_invite(invites, message)
    invites.each do |invite|
      invitation = Invitation.find(invite[1])
      Invite.community_invite(invite[0], invitation, invite[2], message).deliver
    end
  end

  def user_invite(invites)
    invites.each do |invite|
      user = User.find(invite[0])
      Invite.send_invitations(user, invite[1], invite[2], invite[3]).deliver
    end
  end

  def save_activity(text)
    self.activities.create(:action=>text,:user_id=>self.user.nil?  ? 'nil' : self.user._id)
  end

  def save_Invitation_activity(text, community_id, shared_id, user_id)
    @community = Community.find "#{community_id}"
    @community.activities.create(:action=>text, :shared_id => shared_id, :user_id=>user_id)
  end

  def users_count
    self.community_users.where(:status => true).count
  end
  
  def owner
    self.user.first_name
  end

  def shares_count
    self.attachments.total_attachments.count + self.shares.select{|i| i.shared_type == 'Meet'}.map(&:item).uniq.reject{|v| v.status==false}.count
  end

  def unread_notifications(user=nil)
    user = self.user if user.nil?
    last_viewed = self.notifications.where(:user_id => user._id).first.last_viewed rescue nil
    if last_viewed
      self.activities.where(:updated_at.gt => last_viewed, :user_id.ne => user._id).count
    else
      self.activities.where(:updated_at.gt => self.created_at, :user_id.ne => user._id).count
    end
  end

  def get_meets
    shares.to_a.select{|c| c.shared_type=="Meet"}.map(&:item).uniq.reject{|v| v.status==false}.to_json(:only=>[:_id,:description,:name],:methods=>[:item_date,:created_time,:updated_time,:shared_id,:location_details, :user_details,:audio_attachment],:include=>{:pages=>{:only=>[:_id,:page_order],:include=>{:attachment=>{:only=>[:file,:_id],:methods=>:messages}},:methods=>[:page_texts]}}).parse
  end
  
  def get_community_attachments
    attachments.to_a.to_json(:only=>[:_id,:file_type,:content_type,:file_name,:file]).parse
  end
      
  def members
    owner = user
    members = (community_users.undeleted.map(&:user) - owner.to_a).uniq
    invitees = ((invitations.unused.map(&:email) + community_invitees.map(&:email))-community_users.map(&:user).map(&:email)).uniq 
   {:members => members.map(&:email), :members_first_name=>members.map(&:first_name),:members_last_name=>members.map(&:last_name),:invitees =>invitees - (members.map(&:email) + owner.email.to_a),:id => _id.to_s }
  end

  def invite(invites, current_user, message='')
    community_invites, user_invites = [], []
    invites.split(',').each do |invite_email|
      invite_email = invite_email.strip
      user_id = User.where(:email=>invite_email).first
      contact_present = current_user.contacts.where(:email => invite_email).first
      if user_id
        invitation = self.invitations.new(:email => invite_email, :user_id => user_id._id)
        if invitation.save
          contact = Contact.create(:email => invite_email, :first_name =>user_id.first_name, :user_id =>current_user._id) unless contact_present
          community_invites << [current_user.first_name, invitation.id, self.name]
          #@community.save_Invitation_activity("COMMUNITY_INVITED", @community._id, @invitation._id, @current_user._id)
        else
          format.json  { render :json => invitation.all_errors}
        end
      else        
        invited = CommunityInvitee.where(:email => invite_email, :community_id => self._id).first
        invited.nil? ? CommunityInvitee.create(:community_id => self._id, :email => invite_email) : invited.update_attributes(:invited_count => invited.invited_count + 1)
        first_name = (invite_email.split('@'))[0]
        contact = Contact.create(:email => invite_email, :first_name =>first_name, :user_id =>current_user._id) if invited.nil? && !contact_present
        user_invites << [current_user.id, invite_email, self.id, self.name]
      end
    end
      
      self.delay.community_invite(community_invites, message) unless community_invites.blank?
      self.delay.user_invite(user_invites) unless user_invites.blank?      
  end

  def remove_invites(email)
    invited_users=invitations.where(:email=>email) if invitations
    invitees=community_invitees.where(:email=>email) if community_invitees
    invited_users.each {|a| a.update_attributes(:invitation_token => nil)} if invited_users
    invitees.destroy_all   if invitees
  end
  
  def self.send_notifications(user_ids, community_id, current_user)
    current_user_email = current_user.email
    current_user_name = current_user.first_name
    community_name = Community.find(community_id).name
    emails = CommunityUser.where(:community_id => community_id, :subscribe_email => true ).map(&:user).map(&:email) - [current_user_email]
    unsubscriber_names, unsubscriber_emails = [], []
     user_ids.each do |id|
       unsubscriber_names<<User.find(id).first_name
       unsubscriber_emails<<User.find(id).email
     end
    remove_notifications(current_user_email, current_user_name, community_id, community_name, emails, unsubscriber_names)
    unsubscribe_notifications(current_user_email, current_user_name, community_id, community_name, unsubscriber_emails)
  end
   
  def self.remove_notifications(current_user_email, current_user_name, community_id, community_name, emails, unsubscriber_names)
   unsubscriber_names = unsubscriber_names*","
    emails.each do |email|
       Invite.remove_member_notifications(current_user_email, current_user_name, community_id, community_name, email, unsubscriber_names).deliver
    end
  end
  
  def self.unsubscribe_notifications(current_user_email, current_user_name, community_id, community_name, unsubscriber_emails)
    unsubscriber_emails.each do |email|
       Invite.remove_member_notifications(current_user_email, current_user_name, community_id, community_name, email, false).deliver
    end
  end
    
  def self.shared_unsubscribe(communities, current_user)
    current_user_email = current_user.email
    current_user_name = current_user.first_name    
    communities.each do |id|
      community_name = Community.find(id).name
      emails = CommunityUser.where(:community_id => id, :subscribe_email => true ).map(&:user).map(&:email) - [current_user_email]
      shared_unsubscribe_mail(current_user_name, community_name, emails) unless emails.blank?
     end
  end
   
  def self.shared_unsubscribe_mail(current_user_name, community_name, emails) 
     emails.each do |email|
       Invite.shared_unsubscribe_notifications(current_user_name, community_name, email).deliver
     end
  end  
 
   def subscribe
      community_users.where(:user_id=>user._id).first.subscribe_email.to_s
    end
  
  def confirm_notifications(community_id, community_name, current_user)
      current_user_email = current_user.email
      current_user_name = current_user.first_name
      emails = CommunityUser.where(:community_id => community_id, :subscribe_email => true ).map(&:user).map(&:email) - [current_user_email]
      join_notifications(current_user_name, community_id, community_name, emails) unless emails.blank?
    end
    
  def join_notifications(current_user_name, community_id, community_name, emails)
    emails.each do |email|
       Invite.community_accept_notifications(current_user_name, community_id, community_name, email).deliver
    end
  end
  
  def self.search_own(params,user)    
      params[:q] !='' ? user.communities.undeleted.any_of(self.get_criteria(params[:q])) : user.communities.undeleted
  end
  
  def self.search_shared(params,user)
    community_ids = CommunityUser.where(:user_id => "#{user._id}").map(&:community).select{|c| c.user_id != user._id}.map(&:_id)
    params[:q] !='' ? Community.undeleted.any_in(:_id => community_ids).any_of(self.get_criteria(params[:q])) : Community.undeleted.any_in(:_id => community_ids)
  end
  
  def self.get_criteria(query)
    [ {name: /#{query}/i }]
  end

end
