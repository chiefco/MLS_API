class Bookmark
  include Mongoid::Document
  include Mongoid::Timestamps
  include Sunspot::Mongoid
  field :name, :type => String
  field :status, :type => Boolean,:default=>true
  validates_presence_of :name, :message=>"name - Blank Parameter", :code=>3013
  validates_length_of     :name, :message=>"name-invalid length", :maximum =>40,:minimum=>1, :code=>3073, :allow_blank => true
  references_many :bookmarked_contents,:dependent=>:destroy
  has_many :activities, as: :entity
  referenced_in :user
  after_save :sunspot_index
  after_create :create_activity
  after_update :update_activity
  scope :undeleted,self.excludes(:status=>false)

  searchable do
    string :name
    string :user_id
  end
  def self.list
    query = 'bookmarks'
    query += '.where()'
    eval(query)
  end

  def create_activity
    save_activity("BOOKMARK_CREATED")
  end

  def update_activity
    if self.status_changed?
      save_activity("BOOKMARK_DELETED")
    else
      save_activity("BOOKMARK_UPDATED")
    end
  end

  def bookmark_items(text)
    [{text=>self.items.serializable_hash(:except=>:bookmark_ids)}]
  end

  def save_activity(text)
    self.activities.create(:action=>text,:user_id=>self.user.nil?  ? 'nil' : self.user._id)
  end

end
