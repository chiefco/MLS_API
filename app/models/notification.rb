class Notification
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, :type => String
  field :last_viewed, :type => Time

  belongs_to :notifier, polymorphic: true, index: true
  #scopes
  scope :by_user_id, lambda{|user_id| where(:user_id => user_id)}
end
