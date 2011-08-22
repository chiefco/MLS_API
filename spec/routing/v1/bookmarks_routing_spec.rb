require "spec_helper"

describe V1::BookmarksController do
  describe "routing" do

    it "routes to #index" do
      get("/v1/bookmarks").should route_to("v1/bookmarks#index")
    end

    it "routes to #new" do
      get("/v1/bookmarks/new").should route_to("v1/bookmarks#new")
    end

    it "routes to #show" do
      get("/v1/bookmarks/1").should route_to("v1/bookmarks#show", :id => "1")
    end

    it "routes to #edit" do
      get("/v1/bookmarks/1/edit").should route_to("v1/bookmarks#edit", :id => "1")
    end

    it "routes to #create" do
      post("/v1/bookmarks").should route_to("v1/bookmarks#create")
    end

    it "routes to #update" do
      put("/v1/bookmarks/1").should route_to("v1/bookmarks#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/v1/bookmarks/1").should route_to("v1/bookmarks#destroy", :id => "1")
    end

  end
end
