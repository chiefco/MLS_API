class Contact
  include Mongoid::Document
  include Mongoid::Timestamps
  include Sunspot::Mongoid
  SORT_BY_ALLOWED = [ :email, :first_name, :last_name, :job_title, :company]
  ORDER_BY_ALLOWED =  [:asc,:desc]
  field :first_name, :type => String
  field :last_name, :type => String
  field :job_title, :type => String
  field :company, :type => String
  field :email, :type => String
  field :status, :type => Boolean,:default=>true
  field :contact_id, :type => String
  validates_presence_of :first_name,:code=>3011,:message=>"first_name - Blank Parameter"
  validates_presence_of :email,:code=>3002,:message=>"email - Blank Parameter"
  validates_format_of     :email, :message=>"email - Invalid email format", :code=>4001, :with  => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i, :allow_blank => true
  # validates_uniqueness_of :email, :message=>"email - Already exist", :code=>3004, :allow_blank => true
  default_scope :without=>[:created_at,:updated_at]
  referenced_in :user
  belongs_to :contact_user, :class_name => "User", :foreign_key => "contact_id"
  scope :undeleted,self.excludes(:status=>false)
  
  searchable do
    text :first_name do
      first_name.downcase
    end
    text :email
    string :user_id
  end
  
  def self.list(params,paginate_options,user)
    params[:sort_by] = 'created_at' if params[:sort_by].blank? || !SORT_BY_ALLOWED.include?(params[:sort_by].to_sym)
    params[:order_by] = 'desc' if params[:order_by].blank? || !ORDER_BY_ALLOWED.include?(params[:order_by].to_sym)
    if params[:q]
      user.contacts.undeleted.any_of(self.get_criteria(params[:q])).order_by([params[:sort_by].to_sym,params[:order_by].to_sym]).paginate(paginate_options)
    else
      user.contacts.undeleted.order_by([params[:sort_by].to_sym,params[:order_by].to_sym]).paginate(paginate_options)
    end
  end
  
  def self.search(params,user)
    params[:sort_by] = 'created_at' if params[:sort_by].blank? || !SORT_BY_ALLOWED.include?(params[:sort_by].to_sym)
    params[:order_by] = 'desc' if params[:order_by].blank? || !ORDER_BY_ALLOWED.include?(params[:order_by].to_sym)
    user.contacts.undeleted.any_of(self.get_criteria(params[:q])).order_by([params[:sort_by].to_sym,params[:order_by].to_sym])
  end
  
   def self.get_criteria(query)
    [ {first_name: /#{query}/i } , { email: /#{query}/i  }, { last_name: /#{query}/i  }]
  end
end
