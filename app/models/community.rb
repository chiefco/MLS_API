class Community
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, :type => String
  field :description, :type => String
  field :status, :type => Boolean, :default => true
  field :invitees, :type => Array
  referenced_in :user
  references_many :invitations
  references_many :shares
  references_many :community_users
  references_many :community_invitees
  has_many :activities, as: :entity
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
      @community_values=@community_values.merge({"#{f.id}"=>{:name=>"#{f.name}",:id=>"#{f._id}",:users_count => "#{f.users_count}"}})
    end
    return {:community_arrays=>@community,:community_hashes=>@community_values}
  end

  def self.community_invite(invites)
    invites.each do |invite|
      invitation = Invitation.find(invite[1])
      Invite.community_invite(invite[0], invitation, invite[2]).deliver
    end
  end

  def self.user_invite(invites)
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
    self.community_users.count
  end

  def shares_count
    self.shares.uniq_by{|a| a.shared_id}.count
  end

  def get_meets
    shares.to_a.select{|c| c.shared_type=="Meet"}.map(&:item).uniq.reject{|v| v.status==false}.to_json(:only=>[:_id,:description,:name],:methods=>[:item_date,:created_time,:updated_time,:shared_id,:location_details],:include=>{:pages=>{:only=>[:_id,:page_order],:include=>{:attachment=>{:only=>[:file,:_id]}},:methods=>[:page_texts]}}).parse
  end
end
