class Category
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name,:type=>String
  field :show_in_quick_links,:type=>Boolean
  field :parent_id,:type=>String
  referenced_in :item
  #~ references_and_referenced_in_many  :items, :stored_as => :array, :inverse_of => :items
  validates_presence_of :name,:message=>'name - Blank Parameter',:code=>3013
  
  def success_json(selected_fields=nil)
    unless selected_fields.blank?
      response = self.attributes.select { |key,value| selected_fields.include?(key) }
    end 
  end 
end
