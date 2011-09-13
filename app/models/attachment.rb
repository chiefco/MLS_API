class Attachment
  include Mongoid::Document
  include Mongoid::Timestamps
  mount_uploader :file, FileUploader
  belongs_to :attachable, polymorphic: true
  has_many :bookmarked_contents, as: :bookmarkable
  validates_presence_of :attachable_id, :message=>"attachable_id - Blank Parameter", :code=>3034
  validates_presence_of :attachable_type, :message=>"attachable_type - Blank Parameter", :code=>3022
  validates_inclusion_of :attachable_type, :in=>["User","Item","Category","Page"], :message=>"attachable_type - Invalid Parameter", :code=>3050
  SORT_BY_ALLOWED = [:file_name, :size, :content_type]
  ORDER_BY_ALLOWED =  [:asc,:desc]
  field :file_name, type: String
  field :file_type, type: String
  field :content_type, type: String
  field :size, type: Integer
  field :width, type: Integer
  field :height, type: Integer
  protected

  def self.list(attachments,params,paginate_options)
    params[:sort_by] = 'created_at' if params[:sort_by].blank? || !SORT_BY_ALLOWED.include?(params[:sort_by].to_sym)
    params[:order_by] = 'desc' if params[:order_by].blank? || !ORDER_BY_ALLOWED.include?(params[:order_by].to_sym)
    query = 'attachments'
    query +=  '.where(file_type: params[:file_type])' if params[:file_type]
    query += '.any_of(self.get_criteria(params[:q]))' if params[:q]
    query += '.order_by([params[:sort_by],params[:order_by]]).paginate(paginate_options)'
    eval(query)
  end

  def self.get_criteria(query)
    [ {file_name: query} , { size: query }, { content_type: query }]
  end

end
