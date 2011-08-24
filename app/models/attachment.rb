class Attachment
  include Mongoid::Document
  include Mongoid::Timestamps
  mount_uploader :file, FileUploader
  belongs_to :attachable, polymorphic: true
  
  field :file_name, type: String
  field :file_type, type: String
  field :size, type: Integer
  field :width, type: Integer
  field :height, type: Integer
end
