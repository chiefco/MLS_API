require "spec_helper"

describe V1::PagesController do
  describe "routing" do

    it "routes to #index" do
      get("/v1/pages").should route_to("v1/pages#index")
    end

    it "routes to #new" do
      get("/v1/pages/new").should route_to("v1/pages#new")
    end

    it "routes to #show" do
      get("/v1/pages/1").should route_to("v1/pages#show", :id => "1")
    end

    it "routes to #edit" do
      get("/v1/pages/1/edit").should route_to("v1/pages#edit", :id => "1")
    end

    it "routes to #create" do
      post("/v1/pages").should route_to("v1/pages#create")
    end

    it "routes to #update" do
      put("/v1/pages/1").should route_to("v1/pages#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/v1/pages/1").should route_to("v1/pages#destroy", :id => "1")
    end

  end
end
