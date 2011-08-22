class BookmarkedContent
  include Mongoid::Document
  include Mongoid::Timestamps
  field :bookmarkable_type, :type => String
  field :bookmarkable_id, :type => String
  field :start_time, :type => Time
  field :position,:type=>String
  field :show_in_quick_links,:type =>Boolean
end
