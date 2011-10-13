class V1::CommunitiesController < ApplicationController
  before_filter :authenticate_request!,:except=>[:accept_invitation]
  before_filter :find_community,:only=>[:update,:show,:destroy,:members,:invite_member]
  before_filter :add_pagination,:only=>[:index]
  
  # GET /communities
  # GET /communities.xml
  def index
    @communities = Community.undeleted
    respond_to do |format|
      format.json {render :json=>@communities} # index.html.erb
    end
  end

  # GET /communities/1
  # GET /communities/1.xml
  def show
    respond_to do |format|
      if @community.status!=true
        find_parameters
        format.json  {render :json =>@community}
      else
        format.json  {render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # POST /communities
  # POST /communities.xml
  def create
    @community = @current_user.communities.new(params[:community])
    respond_to do |format|
      if @community.save
        find_parameters
        format.json {render :json => @community}
      else
        format.json {render :json => @community.all_errors}
      end
    end
  end

  # PUT /communities/1
  # PUT /communities/1.xml
  def update
    respond_to do |format|
      if @community.status!=true
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

  # DELETE /communities/1
  # DELETE /communities/1.xml
  def destroy
    @community.update_attributes(:status=>true)
    respond_to do |format|
      format.json {render :json=>success }
    end
  end
  
  # Invitation is sent to the member 
  def invite_member
    @invitation=@community.invitations.new(params[:invite_member])
    respond_to do |format|
      if @invitation.save
        Invite.community_invite(@current_user.email,@invitation,@community.name).deliver
        format.json {render :json=>@invitation}
      else
        format.json  { render :json =>@invitation.all_errors}
      end
    end
  end
  
  #Retrieves members of the given community
  def members
  
  end
  def remove_member
    respond_to do |format|
      unless @community_user=CommunityUser.where(:community_id=>params[:remove_member][:community_id],:user_id=>params[:remove_member][:user_id]).first.nil?
        @community_user.update_attributes(:status=>true)
        format.json {render :json=>success}
      else
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end
  
  def accept_invitation
          p "LLLLLLLLLLLLLLL"

    respond_to do |format|
      @invitation=Invitation.where(:invitation_token=>params[:accept_invitation]).first  
      p @invitation
      unless @invitation.nil?
      p "LLLLLLLLLLLLLLL"
      p @invitation
      p @invitation.user
        unless @invitation.user.nil?
          @invitation.community.community_users.create(:user_id=>@invitation.user_id)
          @invitation.update_attributes(:invitation_token=>nil)
          format.json {render :json=>success}
        else
          format.json {render :json=>failure}
        end
      else
        format.json {render :json=>failure}
      end
    end
  end
  
  private
  def find_community 
    @community=@current_user.communities.find(params[:id])
  end
  #find parameters needed for the contacts
  def find_parameters
    @community={:community=>@community.serializable_hash(:only=>[:_id,:name,:description])}.to_success
  end
end
