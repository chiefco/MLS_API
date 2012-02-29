require 'net/http'
require 'net/https'
#~ require 'rest_client'
class V1::SessionsController < Devise::SessionsController

  def create
    user=params[:user]
    params[:user]={}
    params[:user][:email],params[:user][:password]=user.decode_credentials if user && user.is_a?(String)
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
    get_user
    @user.nil?  ? stop_synchronisation: perform_synchronisation(@user)
  end
  
  def community_synchronisation
    get_user;get_communities
    respond_to do |format|
      format.json{render :json =>success.merge(:communities=>@communities)}
    end
  end
  
  private
  #perform synchronisation for the user
  def perform_synchronisation(user)
    initialize_values
    @meets= params[:user][1][:meet].each do |meet|
      unless meet.values[0].empty?
        create_or_update_meets(meet)
      end
    end
    params[:user][0][:task].each do |task|
      unless task.values[0].empty?
        create_or_update_tasks(task)
      end
    end
    get_communities
   respond_to do |format|
      format.json{render :json =>success.merge(:synced_ids=>@synched_meets,:ipad_ids=>@ipad_ids.uniq,:communities=>@communities,:synched_page_ids=>@ipad_page_ids.uniq,:synched_pages=>@synched_pages,:share_ids=>@share_ids,:shared_hashes=>@synched_hash,:task_ids=>@task_ids,:task_hashes=>@synched_tasks,:meets=>params[:user][1][:status]=="true" ? get_meets(true) : get_meets(nil),:other_users=>CommunityUser.other_users(@user._id),:locations=>@user.locations.serializable_hash(:only=>[:_id,:name],:methods=>[:latitude_val,:longitude_val] ))}
    end
  end

  def initialize_values
    @ipad_ids=[];@ipad_page_ids=[]; @share_ids=[];@task_ids=[];@synched_meets={};@synched_pages={};
    @synched_hash={};@synched_tasks={};
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
        location=meet[:location_name]
        meet.delete(:page)
        meet.delete(:share)
        begin
          unless location.nil?
            @location=@user.locations.find_or_create_by(:name=>location.downcase)
            meet[:location_id]=@location._id unless @location.nil?
          end
          @meet= @user.items.create(meet)
          puts @meet.errors.inspect
          unless @meet.nil?
            @id=@meet._id
             create_or_update_share
             create_or_update_pages(@pages)
            @synched_meets=@synched_meets.merge({meet[:meet_id] =>@id.to_s})
            @ipad_ids<<meet[:meet_id]
          end
        rescue Exception => e
          puts e
        end
      elsif status.keys[0]=="delete"
        @deleted_meet=Item.where(:_id=>meet[:cloud_id]).first
        @deleted_meet.update_attributes(:status=>false) unless @deleted_meet.nil?
      else
        @meet=Item.where(:_id=>meet[:cloud_id]).first
        begin
          unless @meet.nil?
            @pages=meet[:page][:new_page]
            @shares=meet[:share]
            location=meet[:location_name]
            @updated_pages=meet[:updated_page]
            meet.delete(:updated_page)
            meet.delete(:page)
            meet.delete(:share)
            unless location.nil?
              @location=@user.locations.find_or_create_by(:name=>location.downcase)
              meet[:location_id]=@location._id unless @location.nil?
            end
            @meet.update_attributes(meet)
            @id=meet[:cloud_id]
            create_or_update_share
            create_or_update_pages(@pages)
            create_or_update_pages(@updated_pages,:update)
            @synched_meets=@synched_meets.merge({meet[:meet_id] =>@id.to_s})
            @ipad_ids<<meet[:meet_id]
          end
        rescue Exception=> e
          puts e
          logger.info e
        end
      end
    end
  end

  def get_meets(value)
    Item.get_meets(@user,value)
  end

  def create_or_update_pages(pages,value=nil)
    @pages=pages
    unless @pages.nil?
      @pages.each do |page|
        unless page[:page_image].empty?
            if value.nil?
              @page=@meet.pages.create(:page_order=>page[:page_order])
              Page.create_page_texts(page[:page_text],@page._id)
              @ipad_page_ids<<page[:page_id]
              @attachment=@page.create_attachment(:attachable_type=>"Page",:attachable_id=>@page._id,:file=>decode_image(@page._id,page[:page_image]))
              File.delete(@file)
            else
              @attachment=Attachment.where(:_id=>page[:cloud_id]).first
              Page.create_page_texts(page[:page_text],@attachment.attachable._id)
              @ipad_page_ids<<page[:page_id]
              @attachment.update_attributes(:file=>decode_image(ActiveSupport::SecureRandom.hex(16),page[:page_image]))
               File.delete(@file)
             end
          @synched_pages=@synched_pages.merge({page[:page_id]=>@attachment._id,:page_texts=>@page_texts})
        end
      end
    end
  end

  def create_or_update_share
    @deleted_shares=@meet.shares.where(:ipad_share=>true)
    @deleted_shares.destroy if @deleted_shares
    @shares[0][:communities].each_with_index do |f,i|
      @share=@meet.shares.create(:user_id=>@user._id,:community_id=>f,:shared_type=>"Meet",:shared_id=>@meet._id,:ipad_share=>true)
      #~ @share.create_activity("SHARE_MEET",f,@meet._id)
      @share_ids<<@shares[1][:share_ids][i]
      @synched_hash=@synched_hash.merge({@shares[1][:share_ids][i]=>@share._id.to_s})
    end
  end

  def create_or_update_tasks(task)
    if task.has_key?("new")
      task[:new].each do |f|
        @task=@user.tasks.create(f)
        @task_ids<<f[:task_id]
        @synched_tasks=@synched_tasks.merge(f[:task_id]=>@task._id)
      end
    else
      task[:update].each do |t|
        @task=Task.where(:_id=>t[:cloud_id]).first
        @task.update_attributes(t)
        @task_ids<<t[:task_id]
        @synched_tasks=@synched_tasks.merge(t[:task_id]=>@task._id)
      end
    end
  end
  
  def get_user
    @user=User.where(:authentication_token=>params[:access_token]).first
  end
  
end
