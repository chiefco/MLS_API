class Notification
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, :type => String
  field :last_viewed, :type => Time

  belongs_to :notifier, polymorphic: true, index: true
end
