class User
  include Mongoid::Document
  # Include default devise modules. Others available are:i
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :confirmable, :database_authenticatable, :registerable, :recoverable, :rememberable, :token_authenticatable, :trackable, :validatable
  field :first_name, :type=> String
  field :last_name, :type=>String
  field :job_title, :type=>String
  field :company, :type=> String
  field :business_unit, :type=> String
  field :status, :type=> Boolean
end
