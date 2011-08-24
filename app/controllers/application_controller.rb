class ApplicationController < ActionController::Base
  after_filter :clear_session
  RESET_TOKEN_SENT={:reset_token_sent=>true}
  RESET_TOKEN_ERROR={:code=>5003,:message=>"Email not found"}
  UNAUTHORIZED={:code=>1004,:message=>"Authentication/Authorization Failed"}
  INVALID_PARAMETER_ID={:code=>3065,:message=>"id -Invalid Parameter"}
  USER_COLUMN=[:status,:remember_token,:remember_created_at,:created_at,:updated_at]
  PAGE_SIZE=10
  PAGE=1
  #~ protect_from_forgery
  
  def authenticate_request!
    @current_user=User.valid_user?(params[:access_token]) if params[:access_token]
    respond_to do |format|
      format.json{render :json=>UNAUTHORIZED}
      format.xml{render :xml=>UNAUTHORIZED,:root=>:error}
    end and return unless @current_user
  end  
  
  def current_user
    @current_user=User.valid_user?(params[:access_token]) if params[:access_token]
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
  
  #maps object to hash with supplied attributes
  def object_to_hash(object,selected_fields=nil)
    unless selected_fields.blank?
      response = object.attributes.select { |key,value| selected_fields.include?(key.to_sym) }
    end 
  end 
  
  #maps object array to hash array with supplied attributes
  def all_objects_to_hash(objects,selected_fields=nil)
    response = []
    unless selected_fields.blank? && objects.blank?
      objects.each do |object|
        response << object.attributes.select { |key,value| selected_fields.include?(key.to_sym) }
      end 
      response
    end 
  end 
  
end
