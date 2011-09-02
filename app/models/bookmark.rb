class Bookmark
  include Mongoid::Document
  include Mongoid::Timestamps
  include Sunspot::Mongoid
  field :name, :type => String
  validates_presence_of :name, :message=>"name - Required parameter missing", :code=>"2009"
  references_many :bookmarked_contents,:dependent=>:destroy
  referenced_in :user
  after_save :sunspot_index
  searchable do
    string :name
    string :user_id
  end
end
