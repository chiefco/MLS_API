class Item
  include Mongoid::Document
  include Mongoid::Timestamps
  acts_as_api
  SORT_BY_ALLOWED = [ :name, :description, :updated_at]
  ORDER_BY_ALLOWED =  [:asc, :desc]
  include Sunspot::Mongoid
  field :name, :type => String
  field :description, :type => String,:default=>""
  field :item_date, :type => Time
  field :end_time, :type => Time
  field :status, :type => Boolean,:default=>true
  field :web_status, :type => Boolean,:default=>true
  field :frequency_count, :type => Integer
  field :template_id, :type => String
  field :location_id, :type => String
  field :location_name, :type => String
  field :current_category_id, :type => String

  validates_presence_of :name,:message=>'name - Blank Parameter',:code=>3013
  #~ validates :name ,:length => { :minimum => 3 ,:maximum =>50,:message=>"name - Invalid length",:code=>3077},:allow_blank=>true
  #~ validates_presence_of :template_id,:message=>'template_id - Blank Parameter',:code=>3025
  belongs_to  :template
  belongs_to  :location, index: true
  belongs_to  :share, index: true

  references_many :topics,:dependent => :destroy
  references_many :attendees,:dependent => :destroy
  references_many :tasks,:dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :pages,:dependent => :destroy
  has_many :attachments, as: :attachable, :dependent=>:destroy
  has_many :bookmarked_contents, as: :bookmarkable, :dependent=>:destroy
  #~ has_many :comments, as: :commentable, :dependent => :destroy
  has_many :activities, as: :entity
  has_many :notifications, as: :notifier, :dependent=>:destroy
  has_many :shares
  has_many :invitations
  referenced_in :user
  references_and_referenced_in_many :categories
  referenced_in :template
  scope :undeleted,self.excludes(:status=>false)
  scope :upcoming,self.where(:item_date.gte=>Date.yesterday)
  scope :today,self.where(:item_date.gte=>Date.yesterday, :item_date.lt=>Date.tomorrow)
  scope :tomorrow,self.where(:item_date.gte=>Date.today, :item_date.lt=>(Date.tomorrow+1.days))
  scope :next_week,self.where(:item_date.gte=>Date.today+7.days)
  scope :past,self.where(:item_date.lt=>Date.today)
  scope :deleted_from_web,self.where(:web_status => false)

  after_save :sunspot_index
  after_create :create_activity
  after_update :update_activity
  
  # Get location details
  def location_details
    meet_location=self.location
    unless meet_location.nil?
      [{:location_id=>meet_location._id.nil? ? '' : "#{meet_location._id.to_s}",:location_name=>meet_location.name.nil? ? '' : meet_location.name, :location_state => meet_location.state.nil?  ? '' : meet_location.state, :location_country => meet_location.country.nil? ? '' : meet_location.country , :latitude_val => meet_location.latitude.nil? ? '' : meet_location.latitude, :longitude_val => meet_location.longitude.nil? ? '' : meet_location.longitude}] 
      else
        []
    end
  end
  
  # Get user details of item
  def user_details
    val=self.user
    unless val.nil?
      {:first_name => val.first_name, :last_name => val.last_name, :email => val.email}
    end
  end
  
  # Get audio attachments
  def audio_attachment
    attachment=self.attachments
    attachment.blank? ? 'nil' : attachment.last.file
  end

  # Create new activity 
  def create_activity
    save_activity("ITEM_CREATED")
  end

  # Update activity
  def update_activity
    if self.status_changed?
      save_activity("ITEM_DELETED")
    else
      save_activity("ITEM_UPDATED")
    end
  end

  searchable do
    string :name do
      name.downcase
    end
    text :description
    string :user_id
  end

  # Check template fields
  def template_fields
    true
  end

  api_accessible :item_with_user do |t|
    t.add :name
    t.add :description
    t.add :meet_date
    t.add :_id
    t.add :frequency_count
  end

  api_accessible :item_detail,:extend=>:item_with_user do |t|
    t.add 'user'
  end

  # Get location for item
  def location_name
    self.location.nil? ? "nil" : self.location.name
  end

  # Get item date
  def item_date
    super().nil? ? "nil" : super().utc.strftime("%d/%m/%Y %H:%M:%S")
  end

  # Get local date for item
  def item_date_local
    self.item_date.to_time.localtime rescue ''
  end

  # Get end time for item
  def end_time
    super().nil? ? "nil" : super().utc.strftime("%d/%m/%Y %H:%M:%S")
  end

  # Get created time for item
  def created_time
    self.created_at.utc.strftime("%d/%m/%Y %H:%M:%S")
  end

  # Get update time for note
  def updated_time
    self.updated_at.utc.strftime("%d/%m/%Y %H:%M:%S")
  end
  
  # get shared ids
  def shared_id
    self.share._id.to_s
  end

  # Get created by
  def created_by
    self.user.first_name
  end
  
  # Get latitude for location
  def latitude
    self.location.latitude rescue nil
  end
  
  # Get longitude for location
  def longitude
    self.location.longitude rescue nil
  end

  # Get page atachment
  def share_attachments(page)
    self.pages[page].attachment
  end
  
  # Get shared teams
  def shared_teams
    ((self.shares.map(&:community).map(&:name)).uniq).join(", ") rescue nil
  end
  
  # Get audio count for item
  def audio_count
    self.attachments.count
  end

  # Get items by sorting
  def upcoming
    date = item_date
    date = Date.strptime(item_date,"%d/%m/%Y %H:%M:%S") if item_date.is_a?(String)

    if date > Date.yesterday && date < Date.tomorrow
      "Today"
    elsif date > Date.today && date < (Date.tomorrow + 1.days)
      "Tommorrow"
    elsif date > (Date.today + 7.days)
      "Next Week"
    elsif date == Date.yesterday
      "Yesterday"
    elsif date < (Date.today)
      "Past Items"
    else
      "Later"
    end
  end

  #Public: Returns the page count for item
  def page_count
    self.pages.count
  end
  

  def self.stats(params,user,item)
    query=""
    query = '{:tasks=>item.tasks.serializable_hash(:only=>[:_id,:description,:due_date,:is_completed])}' if (params[:tasks] == "true")
    query =query.empty? ? {} : eval(query)
    query=query.merge({:topics=>item.topics.serializable_hash(:only=>[:_id,:name,:status])}) if (params[:topics] == "true")
		query=query.merge({:categories=>item.categories.serializable_hash(:only=>[:_id,:name,:status])}) if (params[:categories] == "true")
		return query
  end

  # List all items
  def self.list(params,paginate_options,user)
    params[:sort_by] = 'created_at' if params[:sort_by].blank? || !SORT_BY_ALLOWED.include?(params[:sort_by].to_sym)
    params[:order_by] = 'desc' if params[:order_by].blank? || !ORDER_BY_ALLOWED.include?(params[:order_by].to_sym)
    if params[:q]
      values = user.items.undeleted.any_of(self.get_criteria(params[:q])).order_by([params[:sort_by].to_sym,params[:order_by].to_sym])
      item_count = values.count unless params[:item_count].nil?
      values = values.paginate(paginate_options)
    else
      values=user.items.undeleted.order_by([params[:sort_by].to_sym,params[:order_by].to_sym])
      item_count = values.count unless params[:item_count].nil?
      values = values.paginate(paginate_options)
    end
    if params[:group_by]
      if params[:group_by]=='categories'
        result={}
        user.categories.sort_by{|c| c.name}.each{|c| result[c.name]=c.items}
      elsif params[:group_by]=='upcoming'
        result=user.items.undeleted.upcoming.group_by(&:upcoming)
      elsif params[:group_by]=='past'
        result=user.items.undeleted.past.order_by([:item_date,params[:order_by].to_sym]).group_by(&:upcoming)
      elsif params[:group_by]=='all'
        result=user.items.undeleted.order_by([:item_date,params[:order_by].to_sym]).group_by(&:_id)
      else
        result=user.items.undeleted.order_by([:item_date,params[:order_by].to_sym]).group_by(&:location_name)
      end
      values=group_values(params[:group_by],result)
      item_count = result.count unless params[:item_count].nil?
    end
    if params[:item_count].nil?
      return values
    else
      return item_count
    end
  end

  # Get upcoming items count
  def self.upcoming_meetings_counts(user)
    today = user.items.undeleted.today.group_by(&:upcoming)['Today'].count rescue 0
    tomorrow = user.items.undeleted.tomorrow.group_by(&:upcoming)['Tommorrow'].count rescue 0
    next_week = user.items.undeleted.next_week.group_by(&:upcoming)['Next Week'].count rescue 0
    return items_count = today + tomorrow + next_week
  end

  # Save the new activity
  def save_activity(text)
    self.activities.create(:action=>text,:user_id=>self.user.nil?  ? 'nil' : self.user._id)
  end
  
  def item_messages
    comments.to_a.to_json(:only=>[:_id,:message],:methods=>[:created_time],:include=>{:user=>{:only=>[:email, :first_name, :last_name]}}).parse
  end
  
  # List items for ipad
  def self.get_meets(user,value=nil)
    @meets=[]
    @meets_values={}
    location_values=[]
    unless value.nil?
      user.items.undeleted.each do |f|
        @meets<<f._id.to_s
        meet_location = f.location
        test = nil
        test = meet_location._id.nil? ? '' : "#{meet_location.id}"  unless meet_location.nil?
        location_values=[{:location_id=>test,:location_name=>meet_location.name.nil? ? '' : meet_location.name, :location_state => meet_location.state.nil?  ? '' : meet_location.state, :location_country => meet_location.country.nil? ? '' : meet_location.country , :latitude_val => meet_location.latitude.nil? ? '' : meet_location.latitude, :longitude_val => meet_location.longitude.nil? ? '' : meet_location.longitude}]  unless meet_location.nil?
      @meets_values=@meets_values.merge({f.id=>{:name=>f.name,:id=>f._id,:description=>f.description, :meet_id => "#{test}", :location_details=>location_values,:item_date=>f.item_date, :created_at=>f.created_time,:updated_at=>f.updated_time,:pages=>get_pages(f),:shares=>get_shares(f),:audio => f.attachments.blank? ? 'nil' : f.attachments.last.file}})

      end
      return {:meet_arrays=>@meets,:meet_hashes=>@meets_values}
    else
      return {:meet_arrays=>[],:meet_hashes=>nil}
    end
  end

  # Get sorted items by group
  def self.group_values(group_by,result)
    values=[]
    keys=[]
    result.each do |k,v|
      keys<<k
      b=[]
      v.each do |i|
        x=i.attributes.merge({:id=>i.id,:created_time=>i.created_time,:updated_time=>i.updated_at,:item_date=>i.item_date,:location_name=>i.location_name,:end_time=>i.end_time, :audio_count => i.audio_count})
        x.reject! {|k, v| %w"created_at updated_at location_id category_ids item_date _id".include? k }
        b<<x
      end
      values<<{k=>b}
    end
     return {group_by=>keys,:items=>values}
   end

   # Get pages for item
   def self.get_pages(item)
      @pages_meet=[]
      item.pages.each do|page|
        unless page.attachment.nil?
        @pages_meet<<{:cloud_id=>page.attachment._id,:page_order=>page.page_order,:page_image=>page.attachment.file,:meet_id=>page.item._id,:page_texts=>page.page_texts.to_a.to_json(:only=>[:_id,:content,:position]).parse}
        end
      end
      return @pages_meet
    end

  # Get shares for item
  def self.get_shares(meet)
    @shares_meet=[]
      meet.shares.uniq_by{|a| a.community_id}.each do|share|
        unless share.community_id.nil?
        @shares_meet<<{:community_id=>share.community_id.to_s,:meet_id=>meet._id.to_s,:share_id=>share._id.to_s}
        end
      end
      return @shares_meet
    end
    
  # Get item shaes
  def item_shares
    (self.shares.map(&:community)).uniq
  end
    
 # Send notification for comments    
   def self.comment_notifications(attachment_id, community_id, message, current_user)
      attachment = Attachment.find(attachment_id).attachable
      item_id = attachment.item_id
      page_order = attachment.page_order
      current_user_email = current_user.email
      current_user_name = current_user.first_name
      community_name = Community.find(community_id).name
      emails = CommunityUser.where(:community_id => community_id, :subscribe_email => true ).map(&:user).map(&:email) - [current_user_email]
      send_comment_notify(current_user_name, community_id, community_name, message, emails, item_id, page_order) unless emails.blank?
    end
    
  # Send email for comments
  def self.send_comment_notify(current_user_name, community_id, community_name, message, emails, item_id, page_order)
    emails.each do |email|
       Invite.comment_notifications(current_user_name, community_id, community_name, message, email, item_id, page_order).deliver
    end
  end

end
