class Activity
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :description,:type=>String
  
  belongs_to :activity, polymorphic: true
  referenced_in :user
  
  validates_presence_of :activity_id,:code=>3027,:message=>"activity_id - Required parameter missing"
  validates_presence_of :activity_type,:code=> 3020,:message=>"activity_type - Required parameter missing"
  validates_inclusion_of :activity_type, :in=>["Item","Category","Task","Topic"], :message=>"activity_type  - Required parameter missing", :code=>2015
end