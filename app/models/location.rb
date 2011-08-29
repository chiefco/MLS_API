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
  
  def find_co_ordinates
    latitude,longitude=Geocoder.coordinates(self.name) unless self.latitude.nil? || self.longitude.nil?
    self.latitude=self.compass_point(latitude) unless latitude.nil?
    self.longitude=self.compass_point(longitude) unless longitude.nil?
  end
  
  def compass_point(value)
    Geocoder::Calculations.compass_point(value)
  end
end
