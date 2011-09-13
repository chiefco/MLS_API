class Bookmark
  include Mongoid::Document
  include Mongoid::Timestamps
  include Sunspot::Mongoid
  field :name, :type => String
  validates_presence_of :name, :message=>"name - Required parameter missing", :code=>"3013"
  validates_length_of     :name, :message=>"name-invalid length", :maximum =>40,:minimum=>2, :code=>3073, :allow_blank => true
  references_many :bookmarked_contents,:dependent=>:destroy
  referenced_in :user
  after_save :sunspot_index
  searchable do
    string :name
    string :user_id
  end
end
