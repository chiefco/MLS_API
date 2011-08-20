class TemplateCategory
  include Mongoid::Document
  field :name
  refereced_in :template
end
