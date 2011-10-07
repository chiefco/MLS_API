class Contact
  include Mongoid::Document
  field :first_name, :type => String
  field :last_name, :type => String
  field :job_title, :type => String
  field :company, :type => String
  field :email, :type => Email
end
