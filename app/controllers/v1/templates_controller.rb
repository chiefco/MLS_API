class V1::TemplatesController < ApplicationController
  before_filter :find_template,:only=>[:update,:destroy,:show]
  def index
    @templates = Template.all
    value={:count=>@templates.size,:templates=>@templates}.to_success
    respond_to do |format|
      format.xml  { render :xml => value.to_xml(:root=>:result)}
      format.json  { render :json =>value}
    end
  end
  
  def show
    value={:template=>@template}.to_success
    respond_to do |format|
      format.xml  { render :xml => value.to_xml(:root=>:result) }
      format.json  { render :json =>value.to_json}
    end
  end

  def create
    @template = Template.new(params[:template])
    respond_to do |format|
      if @template.save
        value={:template=>@template}.to_success
        format.xml  { render :xml => value.to_xml(:root=>:result) }
        format.json  { render :json =>value}
      else
        format.xml  { render :xml => @template.all_errors.to_xml(:root=>"errors") }
        format.json { render :json=>  {"errors"=>@template.all_errors }.merge(failure)}
      end
    end
  end

  def update
    respond_to do |format|
      if @template.update_attributes(params[:template])
        value={:template=>@template}.to_success
        format.xml  { render :xml => @template, :status => :created, :location => @template }
        format.json { render :json=> {"template" => { "id"=>@template.id,"name" => @template.name, "description" => @template.description}}.merge(success)}
      else
        format.xml  { render :xml => @template.all_errors.to_xml(:root=>"errors") }
        format.json { render :json=>  {"errors"=>@template.all_errors }.merge(failure)}
      end
    end
  end

  def destroy
    @template.destroy
    respond_to do |format|
      format.xml  { render :xml => success.to_xml(:root=>'xml') }
      format.json  { render :json=> success}
    end
  end
  
  private
  def find_template
    @template = Template.find(params[:id])
  end
end
