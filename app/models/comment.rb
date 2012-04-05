class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  field :message,:type=>String
  field :is_public,:type=>Boolean
  field :status,:type=>Boolean,:default=>true
  field :commentable_type, :type => String
  field :commentable_id, :type => String
  belongs_to :user
  has_many :activities, as: :entity
  belongs_to :commentable, polymorphic: true
  # default_scope :without=>[:created_at,:updated_at]
  validates_inclusion_of :commentable_type, :in=>["Attachment"], :message=>"commentable_type-invalid_parameter", :code=>3084
  validates_presence_of :message,:code=>3086,:message=>"message-blank_parameter"
  scope :undeleted,self.excludes(:status=>false)
  after_create :create_activity

  def create_activity
    self.activities.create(:action=>"COMMENT_CREATED",:user_id=>self.user.nil?  ? 'nil' : self.user._id)
  end

  def user_name
    self.user.first_name
  end
  
  def self.create_comments(user,messages=nil,attachment)
    comments=[]
      unless messages.nil?
          messages.each do |message|
          comment=user.comments.create(:commentable_type=>"Attachment",:commentable_id=>attachment,:message=>message[:message])
          comments<<{message[:comment_id]=>comment._id}
        end
      end
    return comments 
  end
end
