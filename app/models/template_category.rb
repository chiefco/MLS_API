class TemplateCategory
  include Mongoid::Document
  field :name
  referenced_in :template
end
