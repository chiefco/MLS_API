class V1::TemplatesController < ApplicationController
  #~ before_filter :authenticate_request!
  before_filter :find_template,:only=>[:update,:destroy,:show,:add_template_definitions]
  FOR_XML={:methods=>:id,:except=>:_id,:root=>:result}
  
  # Public: To list all templates 
  # Returns all the templates
  def index
    @templates = Template.all
    value={:count=>@templates.size,:templates=>@templates}.to_success
    respond_to do |format|
      format.xml  { render :xml => value.to_xml(FOR_XML)}
      format.json  { render :json =>value}
    end
  end

  # Public: To show template
  def show
    respond_to do |format|
      if @template
        value={:template=>@template.serializable_hash(:only=>[:_id,:name],:include=>{:template_definitions=>{:only=>[:_id,:created_at,:has_topics_section,:has_task_section,:has_attachment_section,:has_text_section,:sequence],:include=>{:custom_page=>{:include=>:custom_page_fields,:only=>[:field_name,:field_type]}}}})}.to_success
        format.xml  { render :xml => value.to_xml(ROOT) }
        format.json  { render :json =>value}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # Public: To create template
  def create
    @template = Template.new(params[:template])
    respond_to do |format|
      if @template.save
        value={:template=>@template.serializable_hash(:only=>[:name,:_id,:description],:include=>{:template_categories=>{:only=>[:_id,:name]}})}.to_success
        format.xml { render :xml => value.to_xml(ROOT) }
        format.json { render :json =>value}
      else
        format.xml { render :xml => @template.all_errors.to_xml(:root=>"errors") }
        format.json { render :json=>  {"errors"=>@template.all_errors }.merge(failure)}
      end
    end
  end

  # Public: To update template
  def update
    respond_to do |format|
      if @template
        if @template.update_attributes(params[:template])
          value={:template=>@template.to_json(:only=>[:name,:_id,:description],:include=>:template_categories)}.to_success
          format.xml { render :xml => value.to_xml(FOR_XML) }
          format.json { render :json =>value}
        else
          format.xml { render :xml => @template.all_errors.to_xml(:root=>"errors") }
          format.json { render :json=>  {"errors"=>@template.all_errors }.merge(failure)}
        end
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # Public: To delete template
  def destroy
     respond_to do |format|
      if @template
        @template.destroy
        format.xml  { render :xml => success.to_xml(:root=>'xml') }
        format.json  { render :json=> success}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # Public: Adds Template Definition to the given template
  def add_template_definitions
    respond_to do |format|
       if @template
         @template_definition=@template.template_definitions.new(params[:template_definition])
         if @template_definition.save
          format.json {render :json=>{:template_definition=>@template_definition.to_json(:except=>[:created_at,:updated_at])}.merge(success)}
         else
           format.json {render :json=>@template_definitions.all_errors}
         end
       else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end
  # Public: Updates the Template Definitions
  def update_template_definitions
    respond_to do |format|
      @template_definition=TemplateDefinition.find(params[:id])
      if @template_definition
        @template_definition.update_attributes(params[:template_definition])
        format.json {render :json=>{:template_definition=>@template_definition.to_json(:except=>[:created_at,:updated_at])}.merge(success)}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(:root=>'xml') }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  private
  # Private: To find template
  def find_template
    @template = Template.find(params[:id])
  end
end
