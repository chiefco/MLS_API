class Category
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Acts::Tree
  include Sunspot::Mongoid
  field :name,:type=>String
  field :show_in_quick_links,:type=>Boolean,:default=>false
  field :parent_id, :type=>String
  field :user_id, :type=>String
  acts_as_tree
  SORT_BY_ALLOWED = [:name, :show_in_quick_links]
  ORDER_BY_ALLOWED = [:asc, :desc]
  references_and_referenced_in_many :items
  has_many :activities, as: :activity, :dependent=>:destroy
  has_many :attachments, as: :attachable, :dependent=>:destroy
  referenced_in :user
  validates_presence_of :name,:message=>'name - Blank Parameter',:code=>3013
  after_save :sunspot_index
  searchable do
    text :name
    string :user_id
  end
  
  def self.list(categories,params,paginate_options)
    params[:sort_by] = 'created_at' if params[:sort_by].blank? || !SORT_BY_ALLOWED.include?(params[:sort_by].to_sym)
    params[:order_by] = 'desc' if params[:order_by].blank? || !ORDER_BY_ALLOWED.include?(params[:order_by].to_sym)
    query = 'categories'
    query +=  '.where(show_in_quick_links: params[:show_in_quick_links])' if params[:show_in_quick_links]
    query += '.any_of(:name=>params[:q])' if params[:q]
    query += '.order_by([params[:sort_by],params[:order_by]]).paginate(paginate_options)'
    eval(query)
  end
  
end
