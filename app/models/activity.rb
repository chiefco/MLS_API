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
      query = 'user.activities'
      query += '.any_of(self.get_criteria(params[:q]))' if params[:q]
      query +='.where(:created_at.gt=>params[:date].to_time,:created_at.lt=>params[:date].to_time.tomorrow)' if params[:date]
      query +='.where(:activity_type=>params[:activity_type])' if params[:activity_type]
      query += '.order_by([params[:sort_by],params[:order_by]]).paginate(paginate_options)'
      eval(query)
    end

  def self.get_criteria(query)
    [ {activity_type: query} , { description: query }]
  end
end