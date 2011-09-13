xml.instruct!
xml.xml do
  xml.reponse "success"
  @tasks.each do |task|
    xml.tasks do
      xml.id task._id
      xml.due_date task.due_date
      xml.is_completed task.is_completed
      xml.description task.description
      xml.item do
          xml.id task.item._id
          xml.name task.item.name
          xml.description task.item.description
      end
    end
  end
end