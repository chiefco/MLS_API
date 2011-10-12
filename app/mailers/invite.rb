class Invite < ActionMailer::Base
  default :from => "MeetLinkShare <info@meetlinkshare.com>"
  
  def community_invite(inviter,invitation,community)
    @inviter,@invitee,@community,@token=inviter,invitation.email,community,invitation.invitation_token
    mail(:from=>@inviter,:to=>@invitee,:subject =>"Invitation to join in community")
  end
end
