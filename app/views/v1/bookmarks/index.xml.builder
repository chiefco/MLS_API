xml.instruct!
xml.xml do
  xml.response "success"
  xml.bookmarks do
    @bookmark.each do |bookmark|
      xml.bookmark do
        xml.id bookmark._id
        xml.name bookmark.name
        xml.bookmarked_contents do
          bookmark.bookmarked_contents.each do |content|
            xml.bookmarked_contents do
              xml.id content._id
              xml.bookmarkable_type content.bookmarkable_type
              xml.bookmarkable_id content.bookmarkable_id
                xml.bookmarkable do
                  xml.id content.bookmarkable._id
                  xml.name content.bookmarkable.name if content.bookmarkable.respond_to?(:name)                  
                  xml.description content.bookmarkable.description if content.bookmarkable.respond_to?(:description)                  
                  xml.page_order content.bookmarkable.page_order if content.bookmarkable.respond_to?(:page_order)                  
                  xml.attachable_type content.bookmarkable.attachable_type if content.bookmarkable.respond_to?(:attachable_type)                  
                  xml.attachable_id content.bookmarkable.attachable_id if content.bookmarkable.respond_to?(:attachable_id)                  
                  xml.file_name content.bookmarkable.file_name if content.bookmarkable.respond_to?(:file_name)                  
                  xml.file_type content.bookmarkable.file_type if content.bookmarkable.respond_to?(:file_type)                  
                end
            end
          end
        end
      end
    end
  end
end