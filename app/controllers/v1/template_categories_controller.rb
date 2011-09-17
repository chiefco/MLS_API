class V1::TemplateCategoriesController < ApplicationController
  before_filter :find_template_category,:only=>[:show,:update,:destroy]
  # GET /template_categories
  # GET /template_categories.xml
  def index
    @template_categories = TemplateCategory.all
    respond_to do |format|
      format.xml  { render :xml => @template_categories }
      format.json{render :json=>@template_categories}
    end
  end

  # GET /template_categories/1
  # GET /template_categories/1.xml
  def show
    respond_to do |format|
      if @template_category
        @template_category=@template_category.serializable_hash(:only=>[:_id,:name])
        format.xml  { render :xml => @template_category }
        format.json{ render :json => @template_category }
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end

  # POST /template_categories
  # POST /template_categories.xml
  def create
    @template_category = TemplateCategory.new(params[:template_category])
    respond_to do |format|
      if @template_category.save
        @template_category=@template_category.serializable_hash(:only=>[:_id,:name])
        format.xml  { render :xml => @template_category.to_xml(ROOT)}
        format.json  { render :json => @template_category }
      else
        format.xml  { render :xml => @template_category.all_errors.to_xml(ROOT)}
        format.json  { render :json => @template_category.all_errors}
      end
    end
  end

  # PUT /template_categories/1
  # PUT /template_categories/1.xml
  def update
    respond_to do |format|
      if @template_category
        if @template_category.update_attributes(params[:template_category])
          @template_category=@template_category.serializable_hash(:only=>[:_id,:name])
          format.xml  { render :xml => @template_category.to_xml(ROOT)}
          format.json  { render :json => @template_category }
        else
          format.xml  { render :xml => @template_category.all_errors.to_xml(ROOT)}
          format.json  { render :json => @template_category.all_errors}
        end
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}        
      end
    end
  end

  # DELETE /template_categories/1
  # DELETE /template_categories/1.xml
  def destroy
    respond_to do |format|
      if @template_category
        @template_category.destroy
        format.xml  { render :xml => success.to_xml(ROOT) }
        format.json  { render :json=> success}
      else
        format.xml  { render :xml => failure.merge(INVALID_PARAMETER_ID).to_xml(ROOT) }
        format.json  { render :json=> failure.merge(INVALID_PARAMETER_ID)}
      end
    end
  end
  
  def find_template_category
    @template_category = TemplateCategory.find(params[:id])
  end
end
