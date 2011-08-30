class Task
  include Mongoid::Document
  include Mongoid::Timestamps
  SORT_BY_ALLOWED = [ :due_date, :is_completed, :description]
  ORDER_BY_ALLOWED =  [:asc,:desc]
  field :due_date, :type => Time
  field :is_completed,:type=> Boolean,:default=>false
  field :assignee_id,:type=> String
  field :description,:type=> String
  references_many :reminders
  has_many :activities, as: :activity, :dependent=>:destroy
  referenced_in :user
  referenced_in :item
  validates_presence_of :description,:code=>"3014",:message=>"description - Blank Parameter"
  def task_item
    {:item=>self.item.nil?  ? "nil" : self.item.to_json(:only=>[:_id,:name])}
  end

  def self.list(params,paginate_options,user)
    params[:sort_by] = 'created_at' if params[:sort_by].blank? || !SORT_BY_ALLOWED.include?(params[:sort_by].to_sym)
    params[:order_by] = 'desc' if params[:order_by].blank? || !ORDER_BY_ALLOWED.include?(params[:order_by].to_sym)
    if params[:q]
      user.tasks.any_of(self.get_criteria(params[:q])).order_by([params[:sort_by].to_sym,params[:order_by].to_sym]).paginate(paginate_options)
    else
      user.tasks.order_by([params[:sort_by].to_sym,params[:order_by].to_sym]).paginate(paginate_options)
    end
  end

  def self.get_criteria(query)
    [ {due_date: query} , { description: query }, { is_completed: query }]
  end
 end
