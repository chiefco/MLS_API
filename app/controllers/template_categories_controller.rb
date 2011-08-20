class TemplateCategoriesController < ApplicationController
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
    @template_category = TemplateCategory.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @template_category }
       format.json{ render :json => @template_category }
    end
  end

  # GET /template_categories/new
  # GET /template_categories/new.xml
  def new
    @template_category = TemplateCategory.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @template_category }
    end
  end

  # GET /template_categories/1/edit
  def edit
    @template_category = TemplateCategory.find(params[:id])
  end

  # POST /template_categories
  # POST /template_categories.xml
  def create
    @template_category = TemplateCategory.new(params[:template_category])

    respond_to do |format|
      if @template_category.save
        format.html { redirect_to(@template_category, :notice => 'Template category was successfully created.') }
        format.xml  { render :xml => @template_category, :status => :created, :location => @template_category }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @template_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /template_categories/1
  # PUT /template_categories/1.xml
  def update
    @template_category = TemplateCategory.find(params[:id])

    respond_to do |format|
      if @template_category.update_attributes(params[:template_category])
        format.html { redirect_to(@template_category, :notice => 'Template category was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @template_category.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /template_categories/1
  # DELETE /template_categories/1.xml
  def destroy
    @template_category = TemplateCategory.find(params[:id])
    @template_category.destroy

    respond_to do |format|
      format.html { redirect_to(template_categories_url) }
      format.xml  { head :ok }
    end
  end
end
