class Invite < ActionMailer::Base
  default :from => "MeetLinkShare <info@meetlinkshare.com>"
  
  def community_invite(inviter,invitation,community,host)
    @inviter,@invitee,@community,@token,@host=inviter,invitation.email,community,invitation.invitation_token,host
    mail(:from=>@inviter,:to=>@invitee,:subject =>"Invitation for virtual team from #{@inviter}")
  end
  
  def send_invitations(user,email,community_id="", community="",host)
    @name ="#{user.first_name} #{user.last_name}"
    @community_id = community_id if !community_id.blank?
    @email, @community = email,community
    @host = host
    mail(:to=>email,:subject =>"Invitation for MeetLinkShare", :reply_to=>"info@meetlinkshare.com")
  end 
  
  def share_community(user,item)
    @user,@item=user,item
    mail(:to=>@user.email,:subject =>"Invitation for MeetLinkShare", :reply_to=>"info@meetlinkshare.com")
  end
end
