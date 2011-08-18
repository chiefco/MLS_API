class TemplateDefinition
  include Mongoid::Document
    field :sequence, :type => Integer
    field :has_attachment_section,:type=>Boolean
    field :has_task_section,:type=>Boolean
    field :has_text_section,:type=>Boolean
    field :has_topic_section,:type=>Boolean
end
