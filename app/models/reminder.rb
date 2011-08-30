class Reminder
  include Mongoid::Document
  include Mongoid::Timestamps
  field :time,:type => Time
  referenced_in :task
  validates_presence_of :time,:code=>"3015",:message=>"time - Blank Parameter"

  def reminder_task
   {:id=>self.task._id,:description=>self.task.description}
  end

end
