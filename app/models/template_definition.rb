class TemplateDefinition
  include Mongoid::Document
  include Mongoid::Timestamps
  field :sequence, :type => Integer
  field :has_attachment_section,:type=>Boolean
  field :has_task_section,:type=>Boolean
  field :has_text_section,:type=>Boolean
  field :has_topic_section,:type=>Boolean
  field :custom_page_id,:type=>String
  referenced_in :template
  has_one :custom_page
  #~ references_one :custom_page
  #~ embedded_in :template
  default_scope :without=>[:created_at,:updated_at,:template_id,:_id]

end
