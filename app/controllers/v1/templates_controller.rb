class V1::TemplatesController < ApplicationController
  # GET /templates
  # GET /templates.xml
  def index
    @templates = Template.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @templates.to_xml(:sub_tests => { :response => :success })}
      format.json  { render :json =>{"count"=>"#{@templates.size}","template"=>@templates}.merge(success)}
    end
  end
  # GET /templates/1
  # GET /templates/1.xml
  def show
    @template = Template.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @template }
      format.json  { render :json =>{"template"=>@template }.merge(success)}
    end
  end

  # GET /templates/new
  # GET /templates/new.xml
  def new
    @template = Template.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @template }
    end
  end

  # GET /templates/1/edit
  def edit
    @template = Template.find(params[:id])
  end

  # POST /templates
  # POST /templates.xml
  def create
    @template = Template.new(params[:template])
    respond_to do |format|
      if @template.save
        format.html { redirect_to(@template, :notice => 'Template was successfully created.') }
        format.xml  { render :xml =>{ "template" => { "id"=>@template.id,"name" => @template.name, "description" => @template.description}}.merge(success).to_xml(:root=>"xml")}
        format.json { render :json=> {"template" => { "id"=>@template.id,"name" => @template.name, "description" => @template.description}}.merge(success) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @template.all_errors.to_xml(:root=>"errors") }
        format.json { render :json=>  {"errors"=>@template.all_errors }.merge(failure)}
      end
    end
  end

  # PUT /templates/1
  # PUT /templates/1.xml
  def update
    @template = Template.find(params[:id])
    respond_to do |format|
      if @template.update_attributes(params[:template])
        format.html { redirect_to(@template, :notice => 'Template was successfully updated.') }
        format.xml  { render :xml => @template, :status => :created, :location => @template }
        format.json { render :json=> {"template" => { "id"=>@template.id,"name" => @template.name, "description" => @template.description}}.merge(success)}
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @template.all_errors.to_xml(:root=>"errors") }
        format.json { render :json=>  {"errors"=>@template.all_errors }.merge(failure)}
      end
    end
  end

  # DELETE /templates/1
  # DELETE /templates/1.xml
  def destroy
    @template = Template.find(params[:id])
    @template.destroy
    respond_to do |format|
      format.html { redirect_to(templates_url) }
      format.xml  { render :xml => success.to_xml(:root=>'xml') }
      format.json  { render :json=> success}
    end
  end
end
