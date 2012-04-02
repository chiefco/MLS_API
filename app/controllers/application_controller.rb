class ApplicationController < ActionController::Base
  include SslRequirement
  after_filter :clear_session
  #~ before_filter :get_user_location

  RESET_TOKEN_SENT={:reset_token_sent=>true}
  RESET_TOKEN_ERROR={:code=>5003,:message=>"Email not found"}
  UNAUTHORIZED={:code=>1004,:message=>"Authentication/Authorization Failed"}
  INVALID_PARAMETER_ID={:code=>3065,:message=>"id -Invalid Parameter"}
  INVALID_CATEGORY_ID={:code=>  3079,:message=>"current_category_id-invalid"}
  BLANK_PARAMETER_ID={:code=>3036,:message=>"id - Blank Parameter"}
  INVALID_DATE={:code=>  3080,:message=>"invalid-date"}
  RECORD_NOT_FOUND={:code=>2096,:message=>'Record does not exist in database'}
  USER_COLUMN=[:status,:remember_token,:remember_created_at,:created_at,:updated_at]
  AUTH_FAILED={:code=>1001,:message=>"Username/Password is incorrect"}
  INVALID_COMMENTABLE={:code=>3085,:message=>"commentable_id-invalid_parameter"}
  CATEGORY_ADDED_ITEM="CATEGORY_ADDED_ITEM"
  ADMIN_PREVILEGE={:code=>  3087,:message=>"not a Admin"}
  FILE_FORMAT={:code=>  6004,:message=>"Not an valid file format"}
  PAGE_SIZE=10
  PAGE=1
  ROOT={:root=>:xml}

  TIME_ZONE_MAPPING={"Europe/Vienna"=>"Vienna", "America/New_York"=>"Eastern Time (US & Canada)", "Asia/Kamchatka"=>"Kamchatka", "America/Sao_Paulo"=>"Brasilia", "Europe/Copenhagen"=>"Copenhagen", "Europe/Dublin"=>"Dublin", "Europe/Bucharest"=>"Bucharest", "Etc/UTC"=>"UTC", "Europe/Amsterdam"=>"Amsterdam", "Asia/Almaty"=>"Almaty", "Australia/Brisbane"=>"Brisbane", "Asia/Kathmandu"=>"Kathmandu", "Europe/Riga"=>"Riga", "Europe/Helsinki"=>"Helsinki", "Europe/Tallinn"=>"Tallinn", "Asia/Vladivostok"=>"Vladivostok", "Pacific/Auckland"=>"Wellington", "Europe/Ljubljana"=>"Ljubljana", "Australia/Darwin"=>"Darwin", "Pacific/Fiji"=>"Fiji", "America/La_Paz"=>"La Paz", "Pacific/Pago_Pago"=>"Samoa", "Asia/Muscat"=>"Abu Dhabi", "Asia/Kuala_Lumpur"=>"Kuala Lumpur", "America/Argentina/Buenos_Aires"=>"Buenos Aires", "America/Chihuahua"=>"Chihuahua", "Asia/Karachi"=>"Karachi", "Asia/Rangoon"=>"Rangoon", "Asia/Kabul"=>"Kabul", "Australia/Perth"=>"Perth", "Europe/Madrid"=>"Madrid", "Asia/Dhaka"=>"Dhaka", "Atlantic/Cape_Verde"=>"Cape Verde Is.", "Asia/Jakarta"=>"Jakarta", "Pacific/Honolulu"=>"Hawaii", "America/Los_Angeles"=>"Pacific Time (US & Canada)", "America/Chicago"=>"Central Time (US & Canada)", "Asia/Krasnoyarsk"=>"Krasnoyarsk", "Australia/Adelaide"=>"Adelaide", "Africa/Casablanca"=>"Casablanca", "Asia/Colombo"=>"Sri Jayawardenepura", "Europe/Moscow"=>"St. Petersburg", "America/Juneau"=>"Alaska", "Asia/Yakutsk"=>"Yakutsk", "Europe/Stockholm"=>"Stockholm", "Asia/Yerevan"=>"Yerevan", "Pacific/Tongatapu"=>"Nuku'alofa", "Europe/Budapest"=>"Budapest", "Africa/Cairo"=>"Cairo", "Europe/Kiev"=>"Kyiv", "Asia/Hong_Kong"=>"Hong Kong", "Europe/Vilnius"=>"Vilnius", "Asia/Kuwait"=>"Kuwait", "Europe/Bratislava"=>"Bratislava", "Europe/Warsaw"=>"Warsaw", "Asia/Taipei"=>"Taipei", "Africa/Nairobi"=>"Nairobi", "Pacific/Port_Moresby"=>"Port Moresby", "Europe/Belgrade"=>"Belgrade", "America/Tijuana"=>"Tijuana", "Asia/Yekaterinburg"=>"Ekaterinburg", "Europe/Sofia"=>"Sofia", "Pacific/Guam"=>"Guam", "Atlantic/South_Georgia"=>"Mid-Atlantic", "Europe/Minsk"=>"Minsk", "America/Lima"=>"Lima", "America/Halifax"=>"Atlantic Time (Canada)", "Africa/Monrovia"=>"Monrovia", "Asia/Novosibirsk"=>"Novosibirsk", "America/St_Johns"=>"Newfoundland", "Asia/Tehran"=>"Tehran", "Europe/Rome"=>"Rome", "America/Santiago"=>"Santiago", "Atlantic/Azores"=>"Azores", "Europe/Prague"=>"Prague", "Europe/Berlin"=>"Bern", "Pacific/Noumea"=>"New Caledonia", "Asia/Calcutta"=>"Kolkata", "America/Monterrey"=>"Monterrey", "Asia/Chongqing"=>"Chongqing", "Europe/Skopje"=>"Skopje", "Asia/Urumqi"=>"Urumqi", "Australia/Sydney"=>"Sydney", "Asia/Baghdad"=>"Baghdad", "Asia/Tokyo"=>"Sapporo", "America/Denver"=>"Mountain Time (US & Canada)", "Africa/Johannesburg"=>"Pretoria", "Asia/Bangkok"=>"Bangkok", "Asia/Baku"=>"Baku", "America/Mazatlan"=>"Mazatlan", "Africa/Harare"=>"Harare", "Asia/Jerusalem"=>"Jerusalem", "Asia/Magadan"=>"Magadan", "Europe/Sarajevo"=>"Sarajevo", "Asia/Singapore"=>"Singapore", "America/Caracas"=>"Caracas", "Asia/Tbilisi"=>"Tbilisi", "Pacific/Majuro"=>"Marshall Is.", "Europe/Lisbon"=>"Lisbon", "Australia/Melbourne"=>"Melbourne", "Europe/Brussels"=>"Brussels", "America/Bogota"=>"Bogota", "Asia/Shanghai"=>"Beijing", "Europe/Istanbul"=>"Istanbul", "Asia/Kolkata"=>"Chennai", "Asia/Irkutsk"=>"Irkutsk", "Asia/Seoul"=>"Seoul", "Europe/Athens"=>"Athens", "Asia/Ulaanbaatar"=>"Ulaan Bataar", "Asia/Riyadh"=>"Riyadh", "America/Guyana"=>"Georgetown", "Asia/Tashkent"=>"Tashkent", "America/Phoenix"=>"Arizona", "America/Guatemala"=>"Central America", "America/Indiana/Indianapolis"=>"Indiana (East)", "Africa/Algiers"=>"West Central Africa", "America/Godthab"=>"Greenland", "Europe/London"=>"London", "Pacific/Midway"=>"International Date Line West", "America/Mexico_City"=>"Guadalajara", "America/Regina"=>"Saskatchewan", "Europe/Paris"=>"Paris", "Australia/Hobart"=>"Hobart", "Europe/Zagreb"=>"Zagreb"}

  def ssl_required?
    logger.info request.env['HTTP_USER_AGENT'] 
    Rails.env.production?
  end

  rescue_from Mongoid::Errors::DocumentNotFound do |exception|
      respond_to do |format|
        if !exception.identifiers.empty?
          format.json{render :json=>{:response=>:failure,:errors=>[RECORD_NOT_FOUND]}}
          format.xml{render :xml=>{:errors=>[RECORD_NOT_FOUND]}.to_failure,:root=>:xml}
        else
          format.json{render :json=>{:response=>:failure,:errors=>[BLANK_PARAMETER_ID]}}
          format.xml{render :xml=>{:errors=>[BLANK_PARAMETER_ID]}.to_failure,:root=>:xml}
      end
    end
  end

  rescue_from BSON::InvalidObjectId do |exception|
    respond_to do |format|
      format.json{render :json=>{:response=>:failure,:errors=>[INVALID_PARAMETER_ID]}}
      format.xml{render :xml=>{:errors=>[INVALID_PARAMETER_ID]}.to_failure,:root=>:xml}
    end
  end

  rescue_from Exception do |exception|
    logger.info exception.inspect
  end
  protect_from_forgery

  def authenticate_request!
    @current_user=User.valid_user?(params[:access_token]) if params[:access_token]
    respond_to do |format|
      format.json{render :json=>UNAUTHORIZED}
      format.xml{render :xml=>UNAUTHORIZED,:root=>:xml}
    end and return unless @current_user
  end

  def success
    {:response=>:success}
  end

  def failure
    {:response=>:failure}
  end

  def clear_session
    session.clear
  end

  def set_page_size
    params[:page_size] ? params[:page_size] : PAGE_SIZE
  end

  def set_page
    params[:page] ? params[:page] : PAGE
  end


  #maps single object to hash with supplied attributes,attributes rename options
  def object_to_hash(object,selected_fields=nil,rename={})
    unless selected_fields.blank?
      response = object.attributes.select { |key,value| selected_fields.include?(key.to_sym) }
      return response if rename.blank?
      rename.each do |key,value|
        response[value.to_s] = response.delete(key.to_s) if response.has_key?(key.to_s)
      end
      response
    end
  end

  def paginate_params
    page=params[:page].to_i
    page_size=params[:page_size].to_i
    params[:page]=PAGE if page.zero?
    params[:page_size]=PAGE_SIZE if page_size.zero?
  end

  #renders missing parameter response
  def render_missing(parameter,code)
    respond_to do |format|
      format.json { render :json=> {:message=>"#{parameter} - Required parameter missing", :code=>code}.to_failure }
      format.xml { render :xml=> {:message=>"#{parameter} - Required parameter missing", :code=>code}.to_failure.to_xml(:root=>"error") }
    end
  end

  def add_pagination
    @paginate_options = {}
    @paginate_options.store(:page,set_page)
    @paginate_options.store(:per_page,set_page_size)
  end

  #renders missing parameter response
  def render_missing_params(missing_params,errors = [])
    missing_params.each do |param|
      errors << { :code=>missing_error_code(param), :message=>"#{param} - Required parameter missing"}
    end
    respond_to do |format|
      format.json { render :json=> {:errors=>errors}.to_failure.to_json }
      format.xml { render :xml=> {:errors=>errors}.to_failure.to_xml(:root=>:result) }
    end
  end


  #gived error code of missing parameter
  def missing_error_code(parameter)
    API_ERRORS["Missing Parameter"].select { |code,message| message.match(/\A#{parameter.to_s}/) }.keys.first
  end

  def get_user_location
    begin
      GeoIp.api_key =YAML.load(ERB.new(File.read("#{RAILS_ROOT}/config/external_apis.yml")).result)['geo_ip']['key']
      GeoIp.timeout = 15
      geo_location = GeoIp.geolocation(request.remote_ip.to_s, { :timezone => true})
      timezone_name = geo_location[:timezone_name]
        Time.zone = TIME_ZONE_MAPPING[timezone_name] if TIME_ZONE_MAPPING[timezone_name]
      rescue
      end    
  end  
end
