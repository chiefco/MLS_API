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
  field :status, :type => Boolean
  field :frequency_count, :type => Integer
  field :template_id, :type => String
  field :location_id, :type => String
  field :current_category_id, :type => String

  validates_presence_of :name,:message=>'name - Blank Parameter',:code=>3013
  validates :name ,:length => { :minimum => 3 ,:maximum =>20,:message=>"name - Invalid length",:code=>3077},:allow_blank=>true
  validates_presence_of :template_id,:message=>'template_id - Blank Parameter',:code=>3025
  belongs_to  :template
  belongs_to  :location

  references_many :topics,:dependent => :destroy
  references_many :attendees,:dependent => :destroy
  references_many :tasks,:dependent => :destroy
  has_many :pages,:dependent => :destroy
  has_many :attachments, as: :attachable, :dependent=>:destroy
  has_many :activities, as: :activity, :dependent=>:destroy
  has_many :bookmarked_contents, as: :bookmarkable
  referenced_in :user
  references_and_referenced_in_many :categories
  referenced_in :template

  after_save :sunspot_index

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
    location=self.location.nil? ? "nil" : self.location.name
  end

  def item_date
    super().strftime("%d/%m/%Y %I:%M %p")
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
      user.items.any_of(self.get_criteria(params[:q])).order_by([params[:sort_by].to_sym,params[:order_by].to_sym]).paginate(paginate_options)
    else
      user.items.order_by([params[:sort_by].to_sym,params[:order_by].to_sym]).paginate(paginate_options)
    end
  end
end
