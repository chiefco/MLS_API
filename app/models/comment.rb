class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  field :message,:type=>String
  field :is_public,:type=>Boolean
  field :status,:type=>Boolean
  field :commentable_type, :type => String
  field :commentable_id, :type => String
  belongs_to :user
  belongs_to :commentable, polymorphic: true
end
