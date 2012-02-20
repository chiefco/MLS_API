class Location
  include Mongoid::Document
  include Geocoder::Model::Mongoid
  include Sunspot::Mongoid
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
    validates_presence_of :name,:message=>'name - Blank Parameter',:code=>3013
  default_scope :only=>ALLOWED_FIELDS
  SORT_BY_ALLOWED = [:name,:created_at,:updated_at]
  ORDER_BY_ALLOWED =  [:asc,:desc]

  searchable do
    string :name
    string :user_id
  end
  
  def latitude
    super().nil? ? "nil" : super().to_f
  end
  
   def longitude
    super().nil? ? "nil" : super().to_f
  end

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

  def self.list(params,paginate_options)
    params[:sort_by] = 'created_at' if params[:sort_by].blank? || !SORT_BY_ALLOWED.include?(params[:sort_by].to_sym)
    params[:order_by] = 'desc' if params[:order_by].blank? || !ORDER_BY_ALLOWED.include?(params[:order_by].to_sym)
    if params[:q]
      Location.any_of(self.get_criteria(params[:q])).order_by([params[:sort_by].to_sym,params[:order_by].to_sym]).paginate(paginate_options)
    else
      Location.order_by([params[:sort_by].to_sym,params[:order_by].to_sym]).paginate(paginate_options)
    end
  end

  def self.get_criteria(query)
    [ {name: query} ]
  end

  def self.get_altitude(location)
    Geocoder.coordinates(location)
  end
end
