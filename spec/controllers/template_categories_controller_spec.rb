require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe TemplateCategoriesController do

  # This should return the minimal set of attributes required to create a valid
  # TemplateCategory. As you add validations to TemplateCategory, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {}
  end

  describe "GET index" do
    it "assigns all template_categories as @template_categories" do
      template_category = TemplateCategory.create! valid_attributes
      get :index
      assigns(:template_categories).should eq([template_category])
    end
  end

  describe "GET show" do
    it "assigns the requested template_category as @template_category" do
      template_category = TemplateCategory.create! valid_attributes
      get :show, :id => template_category.id.to_s
      assigns(:template_category).should eq(template_category)
    end
  end

  describe "GET new" do
    it "assigns a new template_category as @template_category" do
      get :new
      assigns(:template_category).should be_a_new(TemplateCategory)
    end
  end

  describe "GET edit" do
    it "assigns the requested template_category as @template_category" do
      template_category = TemplateCategory.create! valid_attributes
      get :edit, :id => template_category.id.to_s
      assigns(:template_category).should eq(template_category)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new TemplateCategory" do
        expect {
          post :create, :template_category => valid_attributes
        }.to change(TemplateCategory, :count).by(1)
      end

      it "assigns a newly created template_category as @template_category" do
        post :create, :template_category => valid_attributes
        assigns(:template_category).should be_a(TemplateCategory)
        assigns(:template_category).should be_persisted
      end

      it "redirects to the created template_category" do
        post :create, :template_category => valid_attributes
        response.should redirect_to(TemplateCategory.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved template_category as @template_category" do
        # Trigger the behavior that occurs when invalid params are submitted
        TemplateCategory.any_instance.stub(:save).and_return(false)
        post :create, :template_category => {}
        assigns(:template_category).should be_a_new(TemplateCategory)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        TemplateCategory.any_instance.stub(:save).and_return(false)
        post :create, :template_category => {}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested template_category" do
        template_category = TemplateCategory.create! valid_attributes
        # Assuming there are no other template_categories in the database, this
        # specifies that the TemplateCategory created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        TemplateCategory.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => template_category.id, :template_category => {'these' => 'params'}
      end

      it "assigns the requested template_category as @template_category" do
        template_category = TemplateCategory.create! valid_attributes
        put :update, :id => template_category.id, :template_category => valid_attributes
        assigns(:template_category).should eq(template_category)
      end

      it "redirects to the template_category" do
        template_category = TemplateCategory.create! valid_attributes
        put :update, :id => template_category.id, :template_category => valid_attributes
        response.should redirect_to(template_category)
      end
    end

    describe "with invalid params" do
      it "assigns the template_category as @template_category" do
        template_category = TemplateCategory.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        TemplateCategory.any_instance.stub(:save).and_return(false)
        put :update, :id => template_category.id.to_s, :template_category => {}
        assigns(:template_category).should eq(template_category)
      end

      it "re-renders the 'edit' template" do
        template_category = TemplateCategory.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        TemplateCategory.any_instance.stub(:save).and_return(false)
        put :update, :id => template_category.id.to_s, :template_category => {}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested template_category" do
      template_category = TemplateCategory.create! valid_attributes
      expect {
        delete :destroy, :id => template_category.id.to_s
      }.to change(TemplateCategory, :count).by(-1)
    end

    it "redirects to the template_categories list" do
      template_category = TemplateCategory.create! valid_attributes
      delete :destroy, :id => template_category.id.to_s
      response.should redirect_to(template_categories_url)
    end
  end

end
