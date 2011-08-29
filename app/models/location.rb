class Location
  include Mongoid::Document
  include Geocoder::Model::Mongoid 
  field :name,:type=>String
  field :latitude,:type=>String
  field :longitude,:type=>String
  #~ field :item_id, :type => Integer
  has_one :item
  referenced_in :user
  geocoded_by :name 
  #~ after_validation :geocode 
  before_save :find_co_ordinates
  ALLOWED_FIELDS=[:_id,:name,:latitude,:longitude]
  default_scope :only=>ALLOWED_FIELDS

  
  def find_co_ordinates
    latitude,longitude=Geocoder.coordinates(self.name) if self.latitude.nil? || self.longitude.nil?
    self.latitude="#{latitude} #{compass_point(latitude)}" unless latitude.nil?
    self.longitude="#{longitude} #{compass_point(longitude)}" unless longitude.nil?
  end
  
  def compass_point(value)
    Geocoder::Calculations.compass_point(value)
  end
  
  def to_xml(options={})
    options[:only]=ALLOWED_FIELDS
    super(options)
  end
  
  def to_json(options={})
    options[:only]=ALLOWED_FIELDS
    options[:only].delete(:_id)
    options[:methods]=[:id]
    super(options)
  end
end
