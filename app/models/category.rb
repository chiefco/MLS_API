class Category
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Acts::Tree
  field :name,:type=>String
  field :show_in_quick_links,:type=>Boolean
  field :parent_id, :type=>String
  field :user_id, :type=>String 
  acts_as_tree
  references_and_referenced_in_many :items
  referenced_in :user
  validates_presence_of :name,:message=>'name - Blank Parameter',:code=>3013
end
