class Attachment
  include Mongoid::Document
  include Mongoid::Timestamps
  mount_uploader :file, FileUploader
  belongs_to :attachable, polymorphic: true
  
  validates_presence_of :attachable_id, :message=>"attachable_id - Blank Parameter", :code=>3034
  validates_presence_of :attachable_type, :message=>"attachable_type - Blank Parameter", :code=>3022
  validates_inclusion_of :attachable_type, :in=>["User","Item","Category","Page"], :message=>"attachable_type - Invalid Parameter", :code=>3050
  
  field :file_name, type: String
  field :file_type, type: String
  field :size, type: Integer
  field :width, type: Integer
  field :height, type: Integer
end
