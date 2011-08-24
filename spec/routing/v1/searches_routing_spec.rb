require "spec_helper"

describe V1::SearchesController do
  describe "routing" do

    it "routes to #index" do
      get("/v1/searches").should route_to("v1/searches#index")
    end

    it "routes to #new" do
      get("/v1/searches/new").should route_to("v1/searches#new")
    end

    it "routes to #show" do
      get("/v1/searches/1").should route_to("v1/searches#show", :id => "1")
    end

    it "routes to #edit" do
      get("/v1/searches/1/edit").should route_to("v1/searches#edit", :id => "1")
    end

    it "routes to #create" do
      post("/v1/searches").should route_to("v1/searches#create")
    end

    it "routes to #update" do
      put("/v1/searches/1").should route_to("v1/searches#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/v1/searches/1").should route_to("v1/searches#destroy", :id => "1")
    end

  end
end
