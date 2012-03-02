class Revision
  include Mongoid::Document
  include Mongoid::Timestamps
  referenced_in :attachment

  field :version, type: Integer, default: 1  
  field :event, type: String, default: "Added"
  field :size, type: Integer
  field :changed_by, type: String  
  field :versioned_attachment, type: String    
end
