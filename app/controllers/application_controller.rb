class ApplicationController < ActionController::Base
  after_filter :clear_session
  RESET_TOKEN_SENT={:reset_token_sent=>true}
  RESET_TOKEN_ERROR={:response=>:failure,:errors=>{:code=>5003,:message=>"Email not found"}}
  UNAUTHORIZED={:response=>:failure,:errors=>{:code=>1004,:message=>"Authentication/Authorization Failed"}}
  INVALID_PARAMETER_ID={:response=>:failure,:errors=>{:code=>3065,:message=>"id -Invalid Parameter"}}
  RECORD_NOT_FOUND={:response=>:failure,:errors=>{:code=>2096,:message=>'Record does not exist'}}
  USER_COLUMN=[:status,:remember_token,:remember_created_at,:created_at,:updated_at]
  PAGE_SIZE=10
  PAGE=1
  
  rescue_from Mongoid::Errors::DocumentNotFound do |exception|
    respond_to do |format|
      format.json{render :json=>RECORD_NOT_FOUND}
      format.xml{render :xml=>RECORD_NOT_FOUND,:root=>:result}
    end
  end
  
  rescue_from BSON::InvalidObjectId do |exception|
    respond_to do |format|
      format.json{render :json=>INVALID_PARAMETER_ID}
      format.xml{render :xml=>INVALID_PARAMETER_ID,:root=>:result}
    end
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
  
end
