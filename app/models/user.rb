class User
  include Mongoid::Document
  include Mongoid::Timestamps
  acts_as_api
  SORT_BY_ALLOWED = [ :email, :first_name, :last_name, :job_title, :company, :business_unit]
  ORDER_BY_ALLOWED =  [:asc,:desc]
  # Include default devise modules. Others available are:i
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  references_many :items
  references_many :categories
  references_many :bookmarks, :dependent=>:destroy
  has_many :attachments, as: :attachable, :dependent=>:destroy
  attr_accessor :set_password
  
  devise :confirmable, :database_authenticatable, :registerable, :recoverable, :rememberable, :token_authenticatable, :trackable

  validates_presence_of :first_name, :message=>"first_name - Blank Parameter", :code=>2041
  validates_presence_of :last_name, :message=>"last_name - Blank Parameter", :code=>2043
  validates_presence_of   :email, :message=>"email - Blank Parameter", :code=>2032
  validates_uniqueness_of :email, :message=>"email - Already exist", :code=>2035, :case_sensitive => (case_insensitive_keys != false), :allow_blank => true
  validates_format_of     :email, :message=>"email - Invalid email format", :code=>2033, :with  => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i, :allow_blank => true
  validates_presence_of     :password, :message=>"password - Blank Parameter",:code=>2003, :if=>:pass_create_or_update?  
  validates_presence_of     :password_confirmation, :message=>"password_confirmation - Blank Parameter",:code=>2004, :if=>:pass_create_or_update?
  validates_confirmation_of :password, :message=>"password and password_confimation does not match", :code=>2040, :if=>:pass_create_or_update?
  validates_length_of       :password, :message=>"password- Too short(Minimum is 6 characters)", :minimum => 6, :code=>2038, :allow_blank => true, :if=>:pass_create_or_update?
  validates_length_of       :password, :message=>"password- Too long(Maximum is 128 characters)", :maximum =>128, :code=>2039, :allow_blank => true, :if=>:pass_create_or_update?

  field :first_name, :type=> String
  field :last_name, :type=>String
  field :job_title, :type=>String
  field :company, :type=> String
  field :business_unit, :type=> String
  field :status, :type=> Boolean,:default=>true
  
  api_accessible :user_with_out_token do |template|
    template.add :email
    template.add :first_name
    template.add :last_name
    template.add :_id
    template.add :job_title
    template.add :company
    template.add :business_unit
    template.add :sign_in_count
    template.add :current_sign_in_at
    template.add :last_sign_in_at
    template.add :current_sign_in_ip
    template.add :last_sign_in_ip
  end  
  
  api_accessible :user_with_token , :extend=> :user_with_out_token do |template|
    template.add :authentication_token #,:as=>:access_token
  end 
  
  def self.valid_user?(token='')
    self.where(:authentication_token=>token,:status=>true).first
  end
  
  def pass_create_or_update?
    set_password || new_record?
  end 
    
  def build_confirm_success_json
    { "response" => "success", "confirmed" => true }.to_json
  end 
  
  def build_confirm_failure_json
    { "response" => "failure",  "confirmed" => false}.to_json
  end 
  
  def build_confirm_success_xml
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?><result><response>success</response><status>200</status><confirmed>true</confirmed></result>"
  end 
  
  def build_confirm_failure_xml
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?><result><response>failure</response><confirmed>false</confirmed></result>"
  end 
  
  def self.list(params,paginate_options)
    params[:sort_by] = 'created_at' if params[:sort_by].blank? || !SORT_BY_ALLOWED.include?(params[:sort_by].to_sym)
    params[:order_by] = 'desc' if params[:order_by].blank? || !ORDER_BY_ALLOWED.include?(params[:order_by].to_sym)
    if params[:q]
      User.any_of(self.get_criteria(params[:q])).order_by([params[:sort_by].to_sym,params[:order_by].to_sym]).paginate(paginate_options)
    else
      User.order_by([params[:sort_by].to_sym,params[:order_by].to_sym]).paginate(paginate_options)
    end 
  end
  
  def self.get_criteria(query)
    [ {first_name: query} , { last_name: query }, { email: query }, { job_title: query }, { company: query}, { business_unit: query } ]
  end 
  
end
