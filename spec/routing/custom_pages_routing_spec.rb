require "spec_helper"

describe CustomPagesController do
  describe "routing" do

    it "routes to #index" do
      get("/custom_pages").should route_to("custom_pages#index")
    end

    it "routes to #new" do
      get("/custom_pages/new").should route_to("custom_pages#new")
    end

    it "routes to #show" do
      get("/custom_pages/1").should route_to("custom_pages#show", :id => "1")
    end

    it "routes to #edit" do
      get("/custom_pages/1/edit").should route_to("custom_pages#edit", :id => "1")
    end

    it "routes to #create" do
      post("/custom_pages").should route_to("custom_pages#create")
    end

    it "routes to #update" do
      put("/custom_pages/1").should route_to("custom_pages#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/custom_pages/1").should route_to("custom_pages#destroy", :id => "1")
    end

  end
end
