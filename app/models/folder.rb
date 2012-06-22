class Folder
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Acts::Tree
  acts_as_tree
  
  referenced_in :user
  has_many :activities, as: :entity, :dependent => :destroy
  belongs_to :community
  references_many :attachments, :dependent => :destroy
  references_many :shares, :dependent => :destroy
  
  field :name, :type => String
  field :parent_id, :type => String
  field :status, :type => Boolean, :default => true
  field :is_deleted, :type => Boolean, :default => false
  
  validates_presence_of :name,:code=>3013,:message=>"name - Blank Parameter"
  scope :undeleted, self.excludes(:status => false, :is_deleted => false)
  scope :personal, self.where(:status => true, :is_deleted => false, :community_id => nil)
  scope :comm_folders, self.where(:status => true, :is_deleted => false, :parent_id => nil)
  scope :by_id, lambda{|id| where(:_id => id)}
  scope :shared_folders, lambda {|shares| any_in(:_id => shares.map(&:shared_id))}
  scope :community_folders, where(:community_id.ne => nil)
  
  after_create :create_activity
  after_update :update_activity

  # After create folder, create activity
  def create_activity
    save_activity("FOLDER_CREATED")
  end

  # Update activity
  def update_activity
    if self.status_changed?
      save_activity("FOLDER_DELETED")
    else
      save_activity("FOLDER_UPDATED")
    end
  end

   # Save activity
   def save_activity(text)
    self.activities.create(:action=>text,:user_id=>self.user.nil?  ? 'nil' : self.user._id)
  end

  # Get subfolders for folders
  def subfolders
    self.children
  end

  # Get folders children count
  def children_count
    self.children.count
  end
  
  # Get user name for folder
  def user_name
    User.find(self.user_id).first_name
  end

  # Check wheather folder is shared or not?
  def is_shared
    self.shares.count > 0
  end    
  
  # Delete folder and activites
  def self.delete(folders,delete_folder = true)
    Folder.any_in(:_id => folders).destroy_all if delete_folder
    Folder.any_in(:_id => folders).community_folders.destroy_all unless delete_folder
    Activity.any_in(:shared_id => folders).delete_all
  end

  # Make clone for share folder
  def make_clone(community_id, user, parent_id=nil)
    shared_folder = self.clone
    shared_folder.save
    shared_folder.update_attributes(:community_id => community_id, :parent_id => parent_id)
    self.attachments.each {|attachment| attachment.create(community_id, shared_folder._id, user)}
    self.children.each{|folder| folder.make_clone(community_id, user, shared_folder._id)} unless self.children.empty?
  end
end
