require 'net/http'
require 'net/https'
#~ require 'rest_client'
class V1::SessionsController < Devise::SessionsController
  
  def create
    user=params[:user]
    params[:user]={}
    params[:user][:email],params[:user][:password]=user.decode_credentials if user && user.is_a?(String)
    p controller_name
    resource = warden.authenticate!(:scope => resource_name, :recall => "V1::Sessions#index")
    respond_to do |format|
      format.xml{ render :xml=>find_user(resource) ,:root => :user}
      format.json{render :json=>find_user(resource)}
    end
  end
  
  def index
    respond_to do |format|
      format.json{render :json =>failure.merge(AUTH_FAILED)}
    end
  end
  
  def find_user(resource)
    {:user=>resource.serializable_hash(:only=>[:_id,:authentication_token,:email,:first_name,:last_name,:job_title,:company,:sign_in_count,:last_sign_in_at,:current_sign_in_at,:date_of_birth,:last_sign_in_ip])}.merge(success)
  end
  
  # Perform synchronisation for the particular user
  def synchronisation
    uri = URI.parse("http://localhost:3000")
		req = Net::HTTP::Get.new("#{request.path}?".concat(request.query_string))
    @user=User.where(:authentication_token=>params[:access_token]).first
    @user.nil?  ? stop_synchronisation: perform_synchronisation(@user) 
  end
  
  private
  #perform synchronisation for the user
  def perform_synchronisation(user)
    @synched_meets={}
    @ipad_ids=[]
    @ipad_page_ids=[]
    @share_ids=[]
    @synched_pages={}
    @synched_hash={}
    @meets=params[:meet].each do |stat| 
      unless stat.values[0].empty?
        create_or_update_meets(stat)
      end
    end
    get_communities
   respond_to do |format|
      format.json{render :json =>success.merge(:synced_ids=>@synched_meets,:ipad_ids=>@ipad_ids.uniq,:communities=>@communities,:synched_page_ids=>@ipad_page_ids.uniq,:synched_pages=>@synched_pages,:share_ids=>@share_ids,:shared_hashes=>@synched_hash)}
    end
  end
  
  #Invalid user- do not perform synchronisation
  def stop_synchronisation
   respond_to do |format|
      format.json{render :json =>failure.merge(AUTH_FAILED)}
    end
  end
  
  #Retrieves the communities for the user
  def get_communities
    @communities=Community.get_communities(@user)
  end
  
  #Decodes the encoded image 
  def decode_image(name,encoded_image)
    File.open("#{Rails.root}/tmp/#{name}", 'wb') do|f|
      f.write(Base64.decode64("#{encoded_image}"))
    end 
    @file=File.new("#{Rails.root}/tmp/#{name}")
    return @file
  end
  
  def  create_or_update_meets(status)
    status.values.first.each do |meet|
      if status.keys[0]=="new"
        @pages=meet[:page][:new_page]
        @shares=meet[:share]
        meet.delete(:page)
        meet.delete(:share)
        @meet= @user.items.create(meet)
        @id=@meet._id
         create_or_update_share
         create_or_update_pages(@pages)
      else
        @meet=Item.where(:_id=>meet[:cloud_id]).first
        @pages=meet[:page][:new_page]
         @updated_pages=meet[:updated_page]
        meet.delete(:updated_page)
        meet.delete(:page)
        @meet.update_attributes(meet)
        @id=meet[:cloud_id]
        create_or_update_pages(@pages)
        create_or_update_pages(@updated_pages,:update)
      end
      @synched_meets=@synched_meets.merge({meet[:meet_id] =>@id.to_s})
      @ipad_ids<<meet[:meet_id]
    end
  end
  
  def create_or_update_pages(pages,value=nil)
    @pages=pages
    unless @pages.nil?
      @pages.each do |page|
        unless page[:page_image].empty?
            if value.nil?
              @page=@meet.pages.create(:page_order=>page[:page_order])
              @ipad_page_ids<<page[:page_id]
              @attachment=@page.create_attachment(:attachable_type=>"Page",:attachable_id=>@page.id,:file=>decode_image(@page._id,page[:page_image]))
            else
              @attachment=Attachment.where(:_id=>page[:cloud_id]).first
              @ipad_page_ids<<page[:page_id]
              @attachment.update_attributes(:file=>decode_image(@attachment._id,page[:page_image]))
            end
          @synched_pages=@synched_pages.merge({page[:page_id]=>@attachment._id})
        end
      end
    end
  end
  
  def create_or_update_share
    @shares[0][:communities].each_with_index do |f,i|
      @share=@meet.shares.create(:user_id=>@user._id,:community_id=>f,:shared_type=>"Meet",:shared_id=>@meet._id)
      #~ @share.create_activity("SHARE_MEET",f,@meet._id) 
      @share_ids<<@shares[1][:share_ids][i]
      @synched_hash=@synched_hash.merge({@shares[1][:share_ids][i]=>@share._id})
    end
  end
end
