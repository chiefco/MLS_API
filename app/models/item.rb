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
  field :status, :type => Boolean,:default=>true
  field :frequency_count, :type => Integer
  field :template_id, :type => String
  field :location_id, :type => String
  field :current_category_id, :type => String

  validates_presence_of :name,:message=>'name - Blank Parameter',:code=>3013
  validates :name ,:length => { :minimum => 3 ,:maximum =>20,:message=>"name - Invalid length",:code=>3077},:allow_blank=>true
  validates_presence_of :template_id,:message=>'template_id - Blank Parameter',:code=>3025
  belongs_to  :template
  belongs_to  :location
  belongs_to  :share

  references_many :topics,:dependent => :destroy
  references_many :attendees,:dependent => :destroy
  references_many :tasks,:dependent => :destroy
  has_many :pages,:dependent => :destroy
  has_many :attachments, as: :attachable, :dependent=>:destroy
  has_many :bookmarked_contents, as: :bookmarkable
  has_many :comments, as: :commentable
  has_many :activities, as: :entity
  has_many :shares
  has_many :invitations
  referenced_in :user
  references_and_referenced_in_many :categories
  referenced_in :template
  scope :undeleted,self.excludes(:status=>false)

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
    text :name
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
    super().nil? ? "nil" : super().utc.strftime("%d/%m/%Y %I:%M %p")
  end

  def created_time
    self.created_at.to_time.strftime("%d/%m/%Y %I:%M %p")
  end

  def updated_time
    self.updated_at.to_time.strftime("%d/%m/%Y %I:%M %p")
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
      values=user.items.undeleted.any_of(self.get_criteria(params[:q])).order_by([params[:sort_by].to_sym,params[:order_by].to_sym]).paginate(paginate_options)
    else
      values=user.items.undeleted.order_by([params[:sort_by].to_sym,params[:order_by].to_sym]).paginate(paginate_options)
    end
    if params[:group_by]
      if params[:group_by]=='categories'
        result={}
        user.categories.sort_by{|c| c.name}.each{|c| result[c.name]=c.items}
        #~ result=result.first
      else
        result=values.group_by{|i| i.send(params[:group_by]).to_s.split(' ').first}
      end
      values,b=[],[]
      result.each do |k,v|
        v.each do |i|
          x=i.attributes.merge({:id=>i.id,:created_time=>i.created_time,:updated_time=>i.updated_time,:item_date=>i.item_date})
          x.reject! {|k, v| %w"created_at updated_at location_id category_ids item_date _id".include? k }
          b<<x
        end
        values<<{k=>b}
      end
    end
    values
  end
  
  def save_activity(text)
    self.activities.create(:action=>text,:user_id=>self.user.nil?  ? 'nil' : self.user._id)
  end
  
  #~ def as_json(options={})
    #~ options[:only]=[:name,:_id]
    #~ options[:methods]=[:location_name,:item_date,:created_time,:updated_time]
    #~ super(options)
  #~ end
end
