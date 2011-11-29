class Category
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Acts::Tree
  include Sunspot::Mongoid
  field :name,:type=>String
  field :show_in_quick_links,:type=>Boolean,:default=>false
  field :parent_id, :type=>String
  field :user_id, :type=>String
  field :status,:type=>Boolean,:default=>true
  acts_as_tree
  SORT_BY_ALLOWED = [:name, :show_in_quick_links,:updated_at]
  ORDER_BY_ALLOWED = [:asc, :desc]
  references_and_referenced_in_many :items
  has_many :activities, as: :activity, :dependent=>:destroy
  has_many :attachments, as: :attachable, :dependent=>:destroy
  has_many :activities, as: :entity
  referenced_in :user
  validates_presence_of :name,:message=>'name - Blank Parameter',:code=>3013
  scope :undeleted,self.excludes(:status=>false)
  scope :parent_categories,self.where(:parent_id=>nil)
  after_save :sunspot_index
  searchable do
    text :name
    string :user_id
  end
  after_create :create_activity
  after_update :update_activity
  
  def create_activity
    save_activity("CATEGORY_CREATED")
  end
  
  def update_activity
    if self.status_changed? 
      save_activity("CATEGORY_DELETED") 
    elsif self.item_ids_changed?
      save_activity("CATEGORY_ADDED_ITEM")
    else
      save_activity("CATEGORY_UPDATED")
    end
  end
  
  def self.list(categories,params,paginate_options)
    params[:sort_by] = 'created_at' if params[:sort_by].blank? || !SORT_BY_ALLOWED.include?(params[:sort_by].to_sym)
    params[:order_by] = 'desc' if params[:order_by].blank? || !ORDER_BY_ALLOWED.include?(params[:order_by].to_sym)
    query = 'categories'
    query += '.where(show_in_quick_links: params[:show_in_quick_links])' if params[:show_in_quick_links]
    query += '.any_of(:name=>params[:q])' if params[:q]
    query += '.undeleted'
    query +='.parent_categories'  if params[:parent]
    query += '.order_by([params[:sort_by],params[:order_by]]).paginate(paginate_options)'
    eval(query)
  end
  
  def save_activity(text)
    self.activities.create(:action=>text,:user_id=>self.user.nil?  ? 'nil' : self.user._id)
  end
  
  def category_items(text)
    [{text=>self.items.serializable_hash(:except=>:category_ids)}]
  end
  def sub_categories(text1,text2)
    [{text1=>self.items.serializable_hash(:except=>:category_ids)},{text2=>self.children}]
  end
end
