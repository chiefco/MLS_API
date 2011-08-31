class Search
  include Mongoid::Document
  field :name
  validates_uniqueness_of :name, :scope => [:user_id],:code=>7002, :message=>'name - Already exist'
  validates_presence_of :name, :code=>3013, :message=>'name - Blank Parameter'
  referenced_in :user
  
  def to_json(options={})
    options[:only]=[:name,:_id]
    super(options)
  end
  
  def to_xml(options={})
    options[:only]=[:name,:_id]
    super(options)
  end
end
