class Page
  include Mongoid::Document
  include Mongoid::Timestamps

  #fields
  field :page_order, type: Integer
  field :item_id , type: String

#associations
  references_many :page_texts, :dependent=>:destroy
  has_many :bookmarked_contents, as: :bookmarkable
  embeds_many :page_texts
  belongs_to :item
  has_one :attachment, as: :attachable, :dependent=>:destroy

  #validations
  validates_presence_of :item_id, :message=>"item_id - Blank Parameter", :code=>3026
  
  SORT_BY_ALLOWED = [:page_order, :created_at]
  ORDER_BY_ALLOWED = [:asc, :desc]
  
  def self.list(pages,params,paginate_options)
    params[:sort_by] = 'created_at' if params[:sort_by].blank? || !SORT_BY_ALLOWED.include?(params[:sort_by].to_sym)
    params[:order_by] = 'desc' if params[:order_by].blank? || !ORDER_BY_ALLOWED.include?(params[:order_by].to_sym)
    query = 'pages'
    query +=  '.where(page_order: params[:page_order])' if params[:page_order]
    query +=  '.any_of({"page_texts.content"=>"#{params[:q]}"})' if params[:q]
    query += '.order_by([params[:sort_by],params[:order_by]]).paginate(paginate_options)'
    eval(query)
  end
end
