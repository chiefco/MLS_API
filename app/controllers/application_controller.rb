class ApplicationController < ActionController::Base
  include SslRequirement
  after_filter :clear_session

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
  PASSWORD="f9071cfbdbdc4f15bf1e222c1df9987e"
  PAGE=1
  SANBOX_URL="https://sandbox.itunes.apple.com/verifyReceipt"
  LIVE_URL="https://buy.itunes.apple.com/verifyReceipt"
  ROOT={:root=>:xml}
  USER_UNCONFIRMED={:code=>1003,:message=>"You have not yet confirmed your e-mail address, please check your e-mail and confirm your registration"}
  ACCOUNT_DELETED = {:code=>1006,:message=>"Your account has been deleted. Please contact Meetlinkshare support."}

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
    Time.zone = @current_user.timezone if !@current_user.timezone.blank? unless @current_user.nil?
    
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

  # Public: check the user subscription
  # Returns boolean result
  def valid_subscription
    type = @current_user.subscription_type
    file_usage = @current_user.attachments.file_usage.sum(:size)

    case type
    when 'free'
      (file_usage && file_usage > 102400) ? false : true
    when 'monthly'
      (file_usage && file_usage > 2097152) ? false : true
    else
      return true
    end
  end  
end
