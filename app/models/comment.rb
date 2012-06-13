class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  field :message,:type=>String
  field :is_public,:type=>Boolean
  field :status,:type=>Boolean,:default=>true
  field :commentable_type, :type => String
  field :commentable_id, :type => String
  field :community_id, :type => String
  field :item_id , type: String

  belongs_to :user, index: true
  has_many :activities, as: :entity
  belongs_to :commentable, polymorphic: true, index: true
  belongs_to :item, index: true
  # default_scope :without=>[:created_at,:updated_at]
  validates_inclusion_of :commentable_type, :in=>["Attachment"], :message=>"commentable_type-invalid_parameter", :code=>3084
  validates_presence_of :message,:code=>3086,:message=>"message-blank_parameter"
  scope :undeleted,self.excludes(:status=>false)
  after_create :create_activity

  # After comment, create activity
  def create_activity
    commented_community = Community.find(self.community_id) rescue nil
    item = self.item_id
    if  item
        item = Item.find(self.item_id)
        duplicate_activity = commented_community.activities.where(:action => "COMMENT_CREATED", :item_id => item._id, :user_id => self.user_id).first    rescue nil
        if duplicate_activity
          duplicate_activity.update_attributes(:shared_id => self._id, :updated_at => Time.now)
        else
         commented_community.activities.create(:action=>"COMMENT_CREATED", :user_id=>self.user.nil?  ? 'nil' : self.user._id, :shared_id => self._id, :item_id => item._id) 
       end
    else
        page = self.commentable.attachable
        duplicate_activity = commented_community.activities.where(:action => "COMMENT_CREATED", :page_order => page.page_order.to_s, :page_id => page._id, :user_id => self.user_id).first rescue nil
        if duplicate_activity
          duplicate_activity.update_attributes(:shared_id => self._id, :updated_at => Time.now)
        else
          commented_community.activities.create(:action=>"COMMENT_CREATED", :user_id=>self.user.nil?  ? 'nil' : self.user._id, :page_order => page.page_order, :shared_id => self._id, :page_id => page._id) rescue ''
        end      
    end   
  end

  # Get user name for comment
  def user_name
    self.user.first_name
  end
  
  # Get created time for comment
  def created_time
    self.updated_at.utc.strftime("%d/%m/%Y %H:%M:%S")
  end
  
  # Create comment
  def self.create_comments(user,messages=nil,attachment)
    comments=[]
      unless messages.nil?
        messages.each do |message|
          item = attachment.attachable.item if attachment.attachable && attachment.attachable_type =="Page"
          comment=user.comments.create(:commentable_type=>"Attachment",:commentable_id=>attachment,:message=>message[:message],:community_id=>message[:community_id], :item_id => (item && item._id.blank? ? nil : item._id))
          comments<<{message[:comment_id]=>comment._id}
        end
      end
    return comments 
  end
  
end
