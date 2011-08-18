class User
  include Mongoid::Document
  include Mongoid::Timestamps
  acts_as_api
  # Include default devise modules. Others available are:i
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  references_many :items
  devise :confirmable, :database_authenticatable, :registerable, :recoverable, :rememberable, :token_authenticatable, :trackable

  validates_presence_of :first_name, :message=>"first_name - Blank Parameter", :code=>2041
  validates_presence_of :last_name, :message=>"last_name - Blank Parameter", :code=>2043
  validates_presence_of   :email, :message=>"email - Blank Parameter", :code=>2032
  validates_uniqueness_of :email, :message=>"email - Already exist", :code=>2035, :case_sensitive => (case_insensitive_keys != false), :allow_blank => true
  validates_format_of     :email, :message=>"email - Invalid email format", :code=>2033, :with  => /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i, :allow_blank => true
  validates_presence_of     :password, :message=>"password - Blank Parameter",:on=>:create
  validates_presence_of     :password_confirmation, :message=>"password_confirmation - Blank Parameter",:on=>:create
  validates_confirmation_of :password, :message=>"password and password_confimation does not match", :code=>2040,:on=>:create
  validates_length_of       :password, :message=>"Too short(Minimum is 6 characters)", :minimum => 6, :code=>2038, :allow_blank => true,:on=>:create
  validates_length_of       :password, :message=>"Too long(Maximum is 128 characters)", :maximum =>128, :code=>2039, :allow_blank => true,:on=>:create

  field :first_name, :type=> String
  field :last_name, :type=>String
  field :job_title, :type=>String
  field :company, :type=> String
  field :business_unit, :type=> String
  field :status, :type=> Boolean,:default=>true

  api_accessible :user_with_token do |template|
    template.add :email
    template.add :first_name
    template.add :last_name
    template.add :_id
    template.add :job_title
    template.add :company
    template.add :business_unit
    template.add :authentication_token
    template.add :sign_in_count
    template.add :current_sign_in_at
    template.add :last_sign_in_at
    template.add :current_sign_in_ip
    template.add :last_sign_in_ip
  end

  def build_user_create_success_xml
    self.to_xml(:skip_instruct=>true, :only=>[:email, :first_name, :last_name])
  end

  def build_user_create_success_json
    { "response" => "success", "status" => 200, self.class.to_s.downcase =>self.to_json(:only=>[:email, :first_name, :last_name]) }.to_json
  end 
   
  def build_confirm_success_json
    { "response" => "success", "status" => 200, "confirmed" => true }.to_json
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

end
