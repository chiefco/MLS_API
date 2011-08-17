require 'builder'
class Template
  include Mongoid::Document
  field :name, :type => String
  field :description, :type => String
  validates_presence_of :name, :message=>"name - Required parameter missing", :code=>"2009" 
  validates_uniqueness_of :name, :message => 'name - name-already exist', :code=>"2009"
end
