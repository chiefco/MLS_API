class V1::CommunitiesController < ApplicationController
  before_filter :authenticate_request!
  before_filter :find_community,:only=>[:update,:show,:destroy,:members,:invite_member]
  before_filter :find_community_members,:only=>[:members]
  before_filter :add_pagination,:only=>[:index]
  before_filter :detect_missing_params, :only=>[:create]


   def index
    communities = @current_user.communities.undeleted
    shared_communities = CommunityUser.where(:user_id => "#{@current_user._id}").map(&:community).select{|c| c.user_id != @current_user.id && c.status == true}
    invited_members = (communities.map(&:community_invitees).flatten.map(&:email) + communities.map(&:invitations).flatten.map(&:email)).uniq
    
    respond_to do |format|
      format.json {render :json =>  {:communities => communities.to_json(:methods => [:users_count, :shares_count]).parse, :invited_members => invited_members.to_json.parse, :shared_communities => shared_communities.to_json(:methods => [:users_count, :shares_count]).parse}} # index.html.erb
    end
  end

  def show
    @attachments, @items = [], []
    shares = @community.shares.order_by(:created_at.desc)
    share_attachments = shares.select{|i| i.shared_type == 'Attachment' && i.status == true}
    items = shares.select{|i| i.shared_type == 'Meet'}.map(&:item).uniq.reject{|v| v.status==false}
    community_owner = @community.community_users.select{|i| i.user_id == @community.user_id}.map(&:user)
    users = (@community.community_users.map(&:user) - community_owner).uniq
    invitees = ((@community.invitations.map(&:email) + @community.community_invitees.map(&:email)) - @community.community_users.map(&:user).map(&:email)).uniq 
    
    respond_to do |format|
      if @community.status!=false
        format.json  {render :json => {:community => @community.serializable_hash(:only=>[:_id,:name,:description]), :invitees => invitees.to_json.parse, :items => items.to_json(:only=>[:name,:_id,:description], :methods=>[:location_name,:item_date,:end_time,:created_time,:updated_time, :template_id]).parse, :attachments => share_attachments.to_json(:only=>[:_id, :user_id], :methods => [:user_name, :share_attachments]).parse, :users => users.to_json(:only=>[:_id, :first_name, :email]).parse, :community_owner => community_owner.to_json(:only=>[:_id, :first_name, :email]).parse}.to_success}
      else
        format.json  {render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end  

  def create
    unless @current_user.communities.undeleted.count > 5
      @community = @current_user.communities.new(params[:community])
      
      respond_to do |format|
        if @community.save
          community_invitation if params[:invite_email]['users'] != 'use comma separated emails'
          CommunityUser.create(:user_id=>@current_user._id,:community_id=>@community._id,:role_id=>1)
          find_parameters
          format.json {render :json => @community}
        else
          format.json {render :json => @community.all_errors}
        end
      end
    else
      respond_to do |format|
        format.json { render :json=> {:message=>"You can create only 6 teams"}.to_failure }
      end
    end
  end

  def update
    respond_to do |format|
      if @community.status!=false
        if @community.update_attributes(params[:community])
          find_parameters
          format.json {render :json => @community}
        else
          format.json  { render :json =>@community.all_errors}
        end
      else
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  def destroy
    @community.update_attributes(:status=>false)
    respond_to do |format|
      format.json {render :json=>success }
    end
  end

  def multiple_delete
    params[:community].each do |com_id|
      @community = Community.find(com_id)
      @community.update_attributes(:status=>false)
    end
    @community_user = CommunityUser.where(:user_id => "#{@current_user._id}")
    @communities=[]
    @community_user.each do |com_user|
      com = Community.where(:_id => "#{com_user.community_id}", :status => true).first
      @communities<< {:id =>com.id, :name=>com.name,:members=>com.community_users.count,:shares=>com.shares.count, :status => com.status} if com
    end
    respond_to do |format|
      format.json {render :json => {:community =>@communities}.to_success} # index.html.erb
    end
  end

  # Invitation is sent to the member
  def invite_member
    @invitation=@community.invitations.new(params[:invite_member])
    respond_to do |format|
      if @invitation.save
        Invite.community_invite(@current_user.first_name,@invitation,@community.name).deliver
        format.json {render :json=>@invitation}
      else
        format.json  { render :json =>@invitation.all_errors}
      end
    end
  end

  #Retrieves members of the given community
  def members
    respond_to do |format|
      format.json{render :json=>{:members=>@community.members}.to_success}
      format.xml{render :xml=>{:members=>@community.members}.to_success.to_xml(:root=>:result)}
    end
  end

  def remove_member
    respond_to do |format|
      @community_user=CommunityUser.where(:community_id=>params[:remove_member][:community_id],:user_id=>params[:remove_member][:user_id]).first
      unless @community_user.nil?
        @community_user.update_attributes(:status=>false)
        format.json {render :json=>success}
      else
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  #Change the role of the CommunityUser
  def change_role
    respond_to do |format|
      @community_user=CommunityUser.where(:community_id=>params[:change_role][:community_id],:user_id=>params[:change_role][:user_id]).first
      if @community_user
        if @community_user.community.user_id==@current_user._id
          @community_user.update_attributes(:role_id=>params[:change_role][:role_id].nil? ? '0' : params[:change_role][:role_id])
          format.json  { render :json=> success}
        else
          format.json  { render :json=> failure.merge(ADMIN_PREVILEGE)}
        end
      else
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  def accept_invitation
    respond_to do |format|
      @invitation = Invitation.where(:invitation_token=>params[:accept_invitation]).first
      unless @invitation.nil?
        if @invitation.user.nil?
          format.json {render :json => failure.merge({:message => 'Something went wrong'})}
        elsif @invitation.user_id != @current_user.id
          format.json {render :json => failure.merge({:message => 'Please login with the invited user to join the community'})}
        else
            exist_user = @invitation.community.community_users.where(:user_id => @invitation.user_id).first
           if exist_user.nil? || exist_user.blank?
              @invitation.community.community_users.create(:user_id=>@invitation.user_id)
              @invitation.update_attributes(:invitation_token=>nil)
              @community = @invitation.community
              @community.save_Invitation_activity("COMMUNITY_JOINED", @community._id, @invitation._id, @current_user._id)
              format.json {render :json => {:community => @invitation.community.to_json(:only => [:_id, :name]).parse}.to_success}
            else
              @invitation.update_attributes(:invitation_token=>nil)
              format.json {render :json => failure.merge({:message => 'Already you have joined this team'})}
            end
        end
      else
        format.json {render :json => failure.merge({:message => 'Invitation already used'})}
      end
    end
  end

  def detect_missing_params
    param_must = [:name]
    if params.has_key?(:community) && params[:community].is_a?(Hash)
      missing_params = param_must.select { |param| !params[:community].has_key?(param.to_s) }
    else
      missing_params = param_must
    end
    render_missing_params(missing_params) unless missing_params.blank?
  end

  def  invite_from_community
    @community = Community.find(params[:invite_email]['community'])
    community_invitation if params[:invite_email]['users'] != 'use comma separated emails'
    respond_to do |format|
      format.json {render :json => success }
    end
  end
 def member_delete
    community_user = CommunityUser.where(:user_id => params[:id], :community_id => params[:community_id]).first
    respond_to do |format|
      if community_user.delete
        format.json  { render :json => success}
      else
        format.json  { render :json => failure}
      end
    end
  end

  private

  def find_community
    @community = Community.find(params[:id])
  end

  def find_community_members
    @community=Community.find(params[:id]) if @current_user.community_membership_ids.include?(params[:id])
  end

  #find parameters needed for the contacts
  def find_parameters
    @community={:community=>@community.serializable_hash(:only=>[:_id,:name,:description])}.to_success
  end

  def  community_invitation
    @community_invites, @user_invites = [], []
    params[:invite_email]['users'].split(',').each do |invite_email|
      invite_email = invite_email.strip
      @user_id=User.where(:email=>invite_email).first
      if @user_id
        @invitation=@community.invitations.new(:email=>invite_email, :user_id=>@user_id._id)
        if @invitation.save
          @community_invites << [@current_user.first_name, @invitation.id, @community.name]
          #@community.save_Invitation_activity("COMMUNITY_INVITED", @community._id, @invitation._id, @current_user._id)
        else
          format.json  { render :json =>@invitation.all_errors}
        end
      else
        invited = CommunityInvitee.where(:email => invite_email, :community_id => @community._id).first
        invited.nil? ? CommunityInvitee.create(:community_id => @community._id, :email => invite_email) : invited.update_attributes(:invited_count => invited.invited_count + 1)
        @user_invites << [@current_user.id, invite_email, @community.id, @community.name]
      end
    end
      Community.delay.community_invite(@community_invites) unless @community_invites.blank?
      Community.delay.user_invite(@user_invites) unless @user_invites.blank?    
  end
end
