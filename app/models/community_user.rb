class CommunityUser
  include Mongoid::Document
  include Mongoid::Timestamps
  field :role_id,:type=>String,:default=>0
  field :status,:type=>Boolean,:default=>true
  field :user_id,:type=>String
  referenced_in :community
  belongs_to :user

  def self.other_users(user_id)
    users=where(:user_id =>user_id).map(&:community).select{|c|  c.status == true}.to_json(:only=>[:_id,:name,:description],:methods=>[:get_meets, :users_count,:members,:owner]).parse
    return users
  end
end
