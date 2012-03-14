class Attachment
  include Mongoid::Document
  include Mongoid::Timestamps
  include Sunspot::Mongoid
  include Mongoid::Acts::Tree  
  acts_as_tree

  mount_uploader :file, FileUploader
  belongs_to :attachable, polymorphic: true
  belongs_to :user
  belongs_to :community
  referenced_in :folder
  has_many :bookmarked_contents, as: :bookmarkable
  references_many :shares, :dependent => :destroy
  references_many :revisions, :dependent => :destroy
  has_many :activities, as: :entity, :dependent => :destroy
  validates_presence_of :attachable_id, :message=>"attachable_id - Blank Parameter", :code=>3034
  validates_presence_of :attachable_type, :message=>"attachable_type - Blank Parameter", :code=>3022
  validates_inclusion_of :attachable_type, :in=>["User","Item","Page"], :message=>"attachable_type - Invalid Parameter", :code=>3050
  SORT_BY_ALLOWED = [:file_name, :size, :content_type]
  ORDER_BY_ALLOWED =  [:asc,:desc]
  after_destroy :delete_parent
  after_create :create_activity
  # after_update :update_activity, :if => :is_current_version
  after_save :sunspot_index
  
  field :file_name, type: String
  field :file_type, type: String
  field :content_type, type: String
  field :size, type: Integer
  field :width, type: Integer
  field :height, type: Integer
  field :is_deleted, :type => Boolean, :default => false
  field :is_current_version, :type => Boolean, :default => true  
  field :attachment_type, type: String, default: "PERSONAL_ATTACHMENT"  

  scope :current_version,self.excludes(:is_current_version => false)  
  scope :undeleted, self.excludes(:is_deleted => true)

  searchable do
    string :file_name do
      file_name.to_s.downcase
    end
    string :user_id
  end

  def update_activity
    save_activity("USER_ATTACHMENT_UPDATE")    
  end  

  def restore_activity
    save_activity("USER_ATTACHMENT_RESTORE")    
  end    

  protected

  def self.list(attachments,params,paginate_options)
    params[:sort_by] = 'created_at' if params[:sort_by].blank? || !SORT_BY_ALLOWED.include?(params[:sort_by].to_sym)
    params[:order_by] = 'desc' if params[:order_by].blank? || !ORDER_BY_ALLOWED.include?(params[:order_by].to_sym)
    query = 'attachments'
    query +=  '.where(is_deleted: false, is_current_version: true)'
    query +=  '.where(file_type: params[:file_type])' if params[:file_type]
    query +=  '.and(:folder_id=> nil)' if params[:folder_id]
    query +=  '.and(:community_id=> nil)' if params[:user_attachments]
    query += '.any_of(self.get_criteria(params[:q]))' if params[:q]
    #~ query += '.order_by([params[:sort_by],params[:order_by]]).paginate(paginate_options)'
    query += '.order_by([params[:sort_by],params[:order_by]])'
    eval(query)
  end

  def self.delete(attachments)
    Activity.any_in(:shared_id => attachments).delete_all
    Attachment.any_in(_id: attachments).each{|a| a.destroy}
  end

  def self.get_criteria(query)
    [ {file_name: query} , { size: query }, { content_type: query }]
  end

  def create_activity
    save_activity("USER_ATTACHMENT")
  end

  def save_activity(text)
    evaluate_item(a=text) unless self.attachable.nil?
  end

  def user_name
    User.find(self.user_id).first_name
  end

  def has_revision?
    self.parent ? parent_attachment = self.parent : parent_attachment = self
    return true if parent_attachment.revisions.count > 1
  end

  def  evaluate_item(text)
    if self.attachable_type =="User"
      user_id = self.attachable._id.nil?  ? 'nil' : self.attachable._id
      self.activities.create(:action=>text, :user_id=> user_id)
    else
      user_id = self.attachable.item.user.nil?  ? 'nil' : self.attachable.item.user._id
      self.attachable.activities.create(:action=>text, :user_id=> user_id) unless self.attachable_type == "Page"
    end
  end

  def delete_parent
    self.parent.destroy if self.parent
  end
end
