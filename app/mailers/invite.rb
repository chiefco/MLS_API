class Invite < ActionMailer::Base
  default :from => "MeetLinkShare <info@info.meetlinkshare.com>"

  def community_invite(inviter,invitation,community, message)
    @inviter,@invitee,@community,@token, @message=inviter,invitation.email,community,invitation.invitation_token, message
    mail(:to=>@invitee, :subject =>"Invitation for virtual team from #{@inviter}", :reply_to => "no-reply@info.meetlinkshare.com")
  end

  def send_invitations(user,email,community_id="", community="")
    @name ="#{user.first_name} #{user.last_name}"
    @community_id = community_id if !community_id.blank?
    @email, @community = email,community
    mail(:to=>email, :subject =>"Invitation for MeetLinkShare", :reply_to => "no-reply@info.meetlinkshare.com")
  end

  def share_community(user,item)
    @user,@item=user,item
    mail(:to=>@user.email, :subject =>"Invitation for MeetLinkShare", :reply_to => "no-reply@info.meetlinkshare.com")
  end
  
  def share_send_email(user, user_name, community_id, community_name, email, files_length, folders_length, file_names, folder_names)
    @user, @user_name, @community_id,@community_name,@email, @files_length,@folders_length,@files_name, @folders_name = user, user_name,community_id, community_name, email, files_length, folders_length, file_names, folder_names
    mail(:to=>@email, :subject =>"Files shared for virtual team(#{@community_name}) by #{@user_name}", :reply_to => "no-reply@info.meetlinkshare.com")
  end
  
  def upload_send_email(upload_user, user_name, community_id, community_name, email, file_name, file_count)
    @user_name, @community_id, @community_name, @email, @file_name, @file_count = user_name, community_id, community_name, email, file_name, file_count
     mail(:to=>@email, :subject =>"Files uploaded for virtual team(#{@community_name}) by #{@user_name}", :reply_to => "no-reply@info.meetlinkshare.com")
   end
   
  def remove_member_notifications(current_user_email, current_user_name, community_id, community_name, email, names)
    @user_name,  @community_id, @community_name, @email, @names = current_user_name, community_id, community_name, email, names
     mail(:to=>@email, :subject =>"Notifications for virtual team(#{@community_name}) from #{@user_name}", :reply_to => "no-reply@info.meetlinkshare.com")
  end
  
  def shared_unsubscribe_notifications(current_user_name, community_name, email)
    @user_name, @community_name, @email = current_user_name, community_name, email
     mail(:to=>@email, :subject =>"Notifications for virtual team(#{@community_name}) from Meetlinkshare.com", :reply_to => "no-reply@info.meetlinkshare.com")
   end
  
  def share_delete_email(current_user_email,current_user_name,  community_id, community_name, email, count, item_name)
    @user_name, @community_id, @community_name, @email, @count, @item_name = current_user_name, community_id, community_name, email, count, item_name
    mail(:to=>@email, :subject =>"Files deleted for virtual team(#{@community_name}) by #{@user_name}", :reply_to => "no-reply@info.meetlinkshare.com")
  end
  
  def notes_share_send_email(user, user_name, community_id, community_name, email, notes_length,  note_names, notes_id)
      @user, @user_name, @community_id,@community_name,@email, @notes_length, @note_names, @notes_id = user, user_name,community_id, community_name, email, notes_length, note_names, notes_id
    mail(:to=>@email, :subject =>"Notes shared for virtual team(#{@community_name}) by #{@user_name}", :reply_to => "no-reply@info.meetlinkshare.com")
  end
  
  def community_accept_notifications(current_user_name, community_id, community_name, email)
    @user_name, @community_id, @community_name, @email  = current_user_name, community_id, community_name, email
     mail(:to=>@email, :subject =>"#{@user_name}  has joined the team #{@community_name} on Meetlinkshare", :reply_to => "no-reply@info.meetlinkshare.com")
   end
   
  def comment_notifications(current_user_name, community_id, community_name, message, email, item_id, page_order)
    @user_name, @community_id, @community_name, @message, @email, @item_id, @page_order  = current_user_name, community_id, community_name, message, email, item_id, (page_order.to_i - 1)
     mail(:to=>@email, :subject =>"#{@user_name}  commented on your page", :reply_to => "no-reply@info.meetlinkshare.com")
   end
   
  def subscription_notifications(email, current_user_name)
    @email, @user_name  = email, current_user_name
     mail(:to=>@email, :subject =>"Thanks for subscribing to MeetLinkShare Premium", :reply_to => "no-reply@info.meetlinkshare.com")
  end

end
