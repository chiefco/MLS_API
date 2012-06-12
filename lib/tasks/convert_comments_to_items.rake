namespace :items do
  desc "item comments modification"
  task :comments => :environment do
    Comment.where(:item_id => nil).each do |comment|
      comment.update_attributes(:item_id => ((comment.item_id.nil? && comment.commentable && comment.commentable.attachable && comment.commentable.attachable_type !="User" && comment.commentable.attachable.item_id) ? comment.commentable.attachable.item_id : nil)) if comment.commentable_type == "Attachment"
      comment.update_attributes(:item_id => comment.commentable_id) if comment.commentable_type == "Item"
    end
    Comment.where(:commentable_type => "Item").each do |comment|
      comment.update_attributes(:commentable_type => "Attachment", :commentable_id => comment.item.pages.first.attachment._id) if comment.item && !comment.item.pages.blank? && comment.item.pages.first.attachment
    end
  end
end