class Page
  include Mongoid::Document
  include Mongoid::Timestamps

  #fields
  field :page_order, type: Integer
  field :item_id , type: String
  field :status , type: Boolean,:default=>true


#associations
  references_many :page_texts, :dependent=>:destroy
  has_many :bookmarked_contents, as: :bookmarkable
  #~ embeds_many :page_texts
  belongs_to :item
  has_one :attachment, as: :attachable, :dependent=>:destroy
  has_many :activities, as: :entity
  scope :undeleted,self.excludes(:status=>false)

  #validations
  validates_presence_of :item_id, :message=>"item_id - Blank Parameter", :code=>3026

  SORT_BY_ALLOWED = [:page_order, :created_at]
  ORDER_BY_ALLOWED = [:asc, :desc]
  after_create :create_activity
  after_update :update_activity

  def create_activity
    save_activity("PAGE_CREATED")
  end

  def update_activity
    if self.status_changed?
      save_activity("PAGE_DELETED")
    else
      save_activity("PAGE_UPDATED")
    end
  end

  def self.list(pages,params,paginate_options)
    params[:sort_by] = 'created_at' if params[:sort_by].blank? || !SORT_BY_ALLOWED.include?(params[:sort_by].to_sym)
    params[:order_by] = 'desc' if params[:order_by].blank? || !ORDER_BY_ALLOWED.include?(params[:order_by].to_sym)
    query = 'pages'
    query +=  '.where(page_order: params[:page_order])' if params[:page_order]
    query +=  '.any_of({"page_texts.content"=>"#{params[:q]}"})' if params[:q]
    query += '.undeleted'
    query += '.order_by([params[:sort_by],params[:order_by]]).paginate(paginate_options)'
    eval(query)
  end

  def save_activity(text)
    self.item.activities.create(:action=>text,:user_id=>self.item.user.nil?  ? 'nil' : self.item.user._id)
  end

  def self.create_page_texts(pagetexts,id)
    @page_texts=[]
    page=Page.where(:_id=>id).first
    page.page_texts.delete_all
    unless pagetexts.nil?
      pagetexts.each do |text|
        @text=page.page_texts.create(:position=>text[:page_text_position],:content=>text[:page_text_content])
        @page_texts<<{text[:pagetext_id]=>@text._id}
      end
    end
  end
end
