class ApplicationController < ActionController::Base
  after_filter :clear_session
  RESET_TOKEN_SENT={:reset_token_sent=>true}
  RESET_TOKEN_ERROR={:code=>5003,:message=>"Email not found"}
  UNAUTHORIZED={:code=>1004,:message=>"Authentication/Authorization Failed"}
  INVALID_PARAMETER_ID={:code=>3065,:message=>"id -Invalid Parameter"}
  RECORD_NOT_FOUND={:code=>2096,:message=>'Record does not exist'}
  USER_COLUMN=[:status,:remember_token,:remember_created_at,:created_at,:updated_at]
  PAGE_SIZE=10
  PAGE=1
  ROOT={:root=>:result}
  rescue_from Mongoid::Errors::DocumentNotFound do |exception|
    respond_to do |format|
      format.json{render :json=>{:response=>:failure,:errors=>[RECORD_NOT_FOUND]}}
      format.xml{render :xml=>{:errors=>[RECORD_NOT_FOUND]}.to_failure,:root=>:result}
    end
  end

  rescue_from BSON::InvalidObjectId do |exception|
    respond_to do |format|
      format.json{render :json=>{:response=>:failure,:errors=>[INVALID_PARAMETER_ID]}}
      format.xml{render :xml=>{:errors=>[INVALID_PARAMETER_ID]}.to_failure,:root=>:result}
    end
  end
  
  rescue_from Exception do |exception|
    logger.info exception.inspect
  end
  #~ protect_from_forgery

  def authenticate_request!
    @current_user=User.valid_user?(params[:access_token]) if params[:access_token]
    respond_to do |format|
      format.json{render :json=>UNAUTHORIZED}
      format.xml{render :xml=>UNAUTHORIZED,:root=>:result}
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

  #maps object array to hash array with supplied attributes,attributes rename options
  def all_objects_to_hash(objects,selected_fields=nil,rename={})
    responses = []
    unless selected_fields.blank? && objects.blank?
      objects.each do |object|
        responses << object.attributes.select { |key,value| selected_fields.include?(key.to_sym) }
      end
      return responses if rename.blank?
      responses.each do |response|
        rename.each do |key,value|
            response[value.to_s] = response.delete(key.to_s) if response.has_key?(key.to_s)
        end
      end
      responses
    end
  end

  def paginate_params
    page=params[:page].to_i
    page_size=params[:page_size].to_i
    params[:page]=PAGE if page.zero?
    params[:page_size]=PAGE_SIZE if page_size.zero?
  end

  #sets values to attchment to be created
  def set_attachment_options
    params[:attachment][:size] = params[:attachment][:file].size
    params[:attachment][:content_type] = params[:attachment][:file].content_type
    params[:attachment][:file_name] =  params[:attachment][:file].original_filename if params[:attachment][:file_name].blank?
    params[:attachment][:file_type] =  params[:attachment][:file].content_type.split('/').last if params[:attachment][:file_type].blank?
  end
  def add_pagination
    @paginate_options = {}
    @paginate_options.store(:page,set_page)
    @paginate_options.store(:per_page,set_page_size)  
  end
end
