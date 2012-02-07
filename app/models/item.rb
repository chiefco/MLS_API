class Item
  include Mongoid::Document
  include Mongoid::Timestamps
  acts_as_api
  SORT_BY_ALLOWED = [ :name, :description]
  ORDER_BY_ALLOWED =  [:asc,:desc]
  include Sunspot::Mongoid
  field :name, :type => String
  field :description, :type => String
  field :item_date, :type => Time
  field :end_time, :type => Time
  field :status, :type => Boolean,:default=>true
  field :frequency_count, :type => Integer
  field :template_id, :type => String
  field :location_id, :type => String
  field :location_name, :type => String
  field :current_category_id, :type => String

  validates_presence_of :name,:message=>'name - Blank Parameter',:code=>3013
  #~ validates :name ,:length => { :minimum => 3 ,:maximum =>50,:message=>"name - Invalid length",:code=>3077},:allow_blank=>true
  #~ validates_presence_of :template_id,:message=>'template_id - Blank Parameter',:code=>3025
  belongs_to  :template
  belongs_to  :location
  belongs_to  :share

  references_many :topics,:dependent => :destroy
  references_many :attendees,:dependent => :destroy
  references_many :tasks,:dependent => :destroy
  has_many :pages,:dependent => :destroy
  has_many :attachments, as: :attachable, :dependent=>:destroy
  has_many :bookmarked_contents, as: :bookmarkable, :dependent=>:destroy
  has_many :comments, as: :commentable
  has_many :activities, as: :entity
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

  after_save :sunspot_index
  after_create :create_activity
  after_update :update_activity
  
  def create_activity
    save_activity("ITEM_CREATED")
  end
  
  def update_activity
    if self.status_changed? 
      save_activity("ITEM_DELETED") 
    else 
      save_activity("ITEM_UPDATED")
    end
  end
  
  searchable do
    text :name do
      name.downcase
    end
    text :description
    string :user_id
  end

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

  def location_name
    self.location.nil? ? "nil" : self.location.name
  end

  def item_date
    super().nil? ? "nil" : super().strftime("%d/%m/%Y %H:%M:%S")
  end
  
  def item_date_local
    self.item_date.to_time.localtime rescue ''
  end  
  
  def end_time
    super().nil? ? "nil" : super().utc.strftime("%d/%m/%Y %H:%M:%S")
  end

  def created_time
    self.created_at.strftime("%d/%m/%Y %H:%M:%S")
  end

  def updated_time
    self.updated_at.strftime("%d/%m/%Y %H:%M:%S")
  end
  
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
  
  def self.stats(params,user,item)
    query=""
    query = '{:tasks=>item.tasks.serializable_hash(:only=>[:_id,:description,:due_date,:is_completed])}' if (params[:tasks] == "true")
    query =query.empty? ? {} : eval(query)
    query=query.merge({:topics=>item.topics.serializable_hash(:only=>[:_id,:name,:status])}) if (params[:topics] == "true")
		query=query.merge({:categories=>item.categories.serializable_hash(:only=>[:_id,:name,:status])}) if (params[:categories] == "true")
		return query
  end

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
    unless params[:item_count].nil? 
      return item_count 
    else
      return values
    end
  end
  
  def self.upcoming_meetings_counts(user)
    today = user.items.undeleted.today.group_by(&:upcoming)['Today'].count rescue 0
    tomorrow = user.items.undeleted.tomorrow.group_by(&:upcoming)['Tommorrow'].count rescue 0
    next_week = user.items.undeleted.next_week.group_by(&:upcoming)['Next Week'].count rescue 0
    return items_count = today + tomorrow + next_week 
  end  
  
  def save_activity(text)
    self.activities.create(:action=>text,:user_id=>self.user.nil?  ? 'nil' : self.user._id)
  end
  
  def self.get_meets(user,value=nil)
    @meets=[]
    @meets_values={}
    unless value.nil?
      user.items.undeleted.each do |f|
        @meets<<f._id.to_s
        @meets_values=@meets_values.merge({f.id=>{:name=>f.name,:id=>f._id,:description=>f.description,:item_date=>f.item_date,:location_name=>f[:location_name],:created_at=>f.created_time,:updated_at=>f.updated_time,:pages=>get_pages(f)}})     
      end
      return {:meet_arrays=>@meets,:meet_hashes=>@meets_values}
    else
      return {:meet_arrays=>[],:meet_hashes=>nil}
    end
  end
  
  def self.group_values(group_by,result)
    values=[]
    keys=[]
    result.each do |k,v|
      keys<<k
      b=[]
      v.each do |i|
        x=i.attributes.merge({:id=>i.id,:created_time=>i.created_time,:updated_time=>i.updated_at,:item_date=>i.item_date,:location_name=>i.location_name,:end_time=>i.end_time})
        x.reject! {|k, v| %w"created_at updated_at location_id category_ids item_date _id".include? k }
        b<<x
      end
      values<<{k=>b}
    end
     return {group_by=>keys,:items=>values}
   end
   
   def self.get_pages(item)
      @pages_meet=[]
      item.pages.each do|page|
        unless page.attachment.nil?
        @pages_meet<<{:cloud_id=>page.attachment._id,:page_order=>page.page_order,:page_image=>page.attachment.file,:meet_id=>page.item._id}
        end
      end
      return @pages_meet
    end
end
