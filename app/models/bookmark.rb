class Bookmark
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, :type => String
  validates_presence_of :name, :message=>"name - Required parameter missing", :code=>"2009"
  references_many :bookmarked_contents,:dependent=>:destroy
end
