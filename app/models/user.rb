class User
  include Mongoid::Document
  include Mongoid::Timestamps
  acts_as_api
  # Include default devise modules. Others available are:i
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :confirmable, :database_authenticatable, :registerable, :recoverable, :rememberable, :token_authenticatable, :trackable, :validatable
  
  validates_presence_of :first_name, :message=>"first_name - Blank Parameter", :code=>2041
  validates_presence_of :last_name, :message=>"last_name - Blank Parameter", :code=>2043
  
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
end
