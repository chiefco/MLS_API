require "spec_helper"

describe TemplateCategoriesController do
  describe "routing" do

    it "routes to #index" do
      get("/template_categories").should route_to("template_categories#index")
    end

    it "routes to #new" do
      get("/template_categories/new").should route_to("template_categories#new")
    end

    it "routes to #show" do
      get("/template_categories/1").should route_to("template_categories#show", :id => "1")
    end

    it "routes to #edit" do
      get("/template_categories/1/edit").should route_to("template_categories#edit", :id => "1")
    end

    it "routes to #create" do
      post("/template_categories").should route_to("template_categories#create")
    end

    it "routes to #update" do
      put("/template_categories/1").should route_to("template_categories#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/template_categories/1").should route_to("template_categories#destroy", :id => "1")
    end

  end
end
