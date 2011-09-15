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
  references_many :tasks,:dependent => :destroy
  references_many :activities,:dependent => :destroy
  references_many :locations
  references_many :searches
  attr_accessor :set_password

  devise :confirmable, :database_authenticatable, :registerable, :recoverable, :rememberable, :token_authenticatable, :trackable
  attr_protected :authentication_token,:is_admin,:reset_password_token,:confirmation_token
  attr_accessible :email,:password,:password_confirmation,:first_name,:last_name,:company,:business_unit,:job_title

  validates_presence_of :first_name, :message=>"first_name - Blank Parameter", :code=>3010
  validates_presence_of :last_name, :message=>"last_name - Blank Parameter", :code=>3011
  validates_presence_of   :email, :message=>"email - Blank Parameter", :code=>3002
  validates_uniqueness_of :email, :message=>"email - Already exist", :code=>3004, :case_sensitive => (case_insensitive_keys != false), :allow_blank => true
  validates_format_of     :email, :message=>"email - Invalid email format", :code=>4001, :with  => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i, :allow_blank => true
  validates_presence_of     :password, :message=>"password - Blank Parameter",:code=>3066, :if=>:pass_create_or_update?
  validates_presence_of     :password_confirmation, :message=>"password_confirmation - Blank Parameter",:code=>3079, :if=>:pass_create_or_update?
  validates_confirmation_of :password, :message=>"password and password_confirmation does not match", :code=>3009, :if=>:pass_create_or_update?
  validates_length_of       :password, :message=>"password - Parameter length less than 6", :minimum => 6, :code=>3005, :allow_blank => true, :if=>:pass_create_or_update?
  validates_length_of       :password_confirmation, :message=>"password_confirmation - Parameter length less than 6", :minimum => 6, :code=>3007, :allow_blank => true, :if=>:pass_create_or_update?
  validates_length_of       :password_confirmation, :message=>"password_confirmation - Parameter length greater than 32", :maximum =>32, :code=>3008, :allow_blank => true, :if=>:pass_create_or_update?
  validates :first_name ,:length => { :minimum => 1 ,:maximum =>40,:message=>"first_name - Invalid length",:code=>3074,:allow_blank=>true}
  validates :last_name ,:length => { :minimum => 1 ,:maximum =>40,:message=>" last_name - Invalid length",:code=>3075,:allow_blank=>true}
  validates :company ,:length => { :minimum => 1 ,:maximum =>80,:message=>"company - Invalid length",:code=>3077},:allow_blank=>true
  validates :job_title ,:length => {:maximum =>80,:message=>"job_title - Invalid length",:code=>3078}
  validates :business_unit ,:length => {:maximum =>80,:message=>"business_unit - Invalid length",:code=>3076}
  validates_format_of       :password, :with =>  /^\S*$/,:message=>"password- Invalid should not contain space", :code=>2040, :if=>:pass_create_or_update?

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
    template.add :_id, :as=>:id
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
