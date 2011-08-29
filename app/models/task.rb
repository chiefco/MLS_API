class Task
  include Mongoid::Document
  include Mongoid::Timestamps
  field :due_date, :type => Time
  field :is_completed,:type=> Boolean,:default=>false
  field :assignee_id,:type=> String
  field :description,:type=> String
  references_many :reminders
  referenced_in :user
  referenced_in :item
  validates_presence_of :description,:code=>"3014",:message=>"description - Blank Parameter"
  def task_item
    {:item=>self.item.nil?  ? "nil" : self.item.to_json(:only=>[:_id,:name])}
  end
 end
