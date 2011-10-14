class Permission
  include Mongoid::Document
  include Mongoid::Timestamps
  field :role_name,:type=>String
  field :can_view,:type=>String,:default=>true
  field :can_edit,:type=>Boolean
  field :can_comment,:type=>Boolean
  field :can_share,:type=>Boolean
  has_one :share
end
