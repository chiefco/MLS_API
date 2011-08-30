class Activity
  include Mongoid::Document
  include Mongoid::Timestamps
  SORT_BY_ALLOWED = [ :activity_type,:created_at]
  ORDER_BY_ALLOWED =  [:asc,:desc]
  field :description,:type=>String
  
  belongs_to :activity, polymorphic: true
  referenced_in :user
  
  validates_presence_of :activity_id,:code=>3027,:message=>"activity_id - Required parameter missing"
  validates_presence_of :activity_type,:code=> 3020,:message=>"activity_type - Required parameter missing"
  validates_inclusion_of :activity_type, :in=>["Item","Category","Task","Topic"], :message=>"activity_type  - Required parameter missing", :code=>2015
  
    def self.list(params,paginate_options,user)
    params[:sort_by] = 'created_at' if params[:sort_by].blank? || !SORT_BY_ALLOWED.include?(params[:sort_by].to_sym)
    params[:order_by] = 'desc' if params[:order_by].blank? || !ORDER_BY_ALLOWED.include?(params[:order_by].to_sym)
    if params[:q]
      acitvities=user.activities.any_of(self.get_criteria(params[:q])).order_by([params[:sort_by].to_sym,params[:order_by].to_sym]).paginate(paginate_options)
    else
      acitvities=user.activities.order_by([params[:sort_by].to_sym,params[:order_by].to_sym]).paginate(paginate_options)
    end 
  end
  
  def self.get_criteria(query)
    [ {activity_type: query} , { description: query }]
  end 
end