class Folder
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Acts::Tree
  acts_as_tree
  
  referenced_in :user
  has_many :activities, as: :entity, :dependent => :destroy
  references_many :attachments, :dependent => :destroy
  references_many :shares, :dependent => :destroy
  
  field :name, :type => String
  field :parent_id, :type => String
  field :status, :type => Boolean, :default => true
  field :is_deleted, :type => Boolean, :default => false
  
  validates_presence_of :name,:code=>3013,:message=>"name - Blank Parameter"
  scope :undeleted,self.excludes(:status => false, :is_deleted => true)

  after_create :create_activity
  after_update :update_activity

  def create_activity
    save_activity("FOLDER_CREATED")
  end

  def update_activity
    if self.status_changed?
      save_activity("FOLDER_DELETED")
    else
      save_activity("FOLDER_UPDATED")
    end
  end

   def save_activity(text)
    self.activities.create(:action=>text,:user_id=>self.user.nil?  ? 'nil' : self.user._id)
  end

  def subfolders
    self.children
  end

  def children_count
    self.children.count
  end
  
  def user_name
    User.find(self.user_id).first_name
  end
  
  def self.delete(folders)
    Folder.any_in(:_id => folders).destroy_all
    Activity.any_in(:shared_id => folders).delete_all
  end

end
