class Invite < ActionMailer::Base
  default :from => "MeetLinkShare <info@meetlinkshare.com>"
  
  def community_invite(inviter,invitation,community)
    @inviter,@invitee,@community,@token=inviter,invitation.email,community,invitation.invitation_token
    mail(:from=>@inviter,:to=>@invitee,:subject =>"Invitation to join in community")
  end
  def send_invitations(user,email)
    @name ="#{user.first_name} #{user.first_name}"
    mail(:to=>email,:subject =>"Invitation for MeetLinkShare", :reply_to=>"info@meetlinkshare.com")
  end 
  def share_community(user,item)
    @user,@item=user,item
    mail(:to=>@user.email,:subject =>"Invitation for MeetLinkShare", :reply_to=>"info@meetlinkshare.com")
  end
end
