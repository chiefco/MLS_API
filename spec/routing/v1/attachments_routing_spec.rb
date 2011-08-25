require "spec_helper"

describe V1::AttachmentsController do
  describe "routing" do

    it "routes to #index" do
      get("/v1/attachments").should route_to("v1/attachments#index")
    end

    it "routes to #new" do
      get("/v1/attachments/new").should route_to("v1/attachments#new")
    end

    it "routes to #show" do
      get("/v1/attachments/1").should route_to("v1/attachments#show", :id => "1")
    end

    it "routes to #edit" do
      get("/v1/attachments/1/edit").should route_to("v1/attachments#edit", :id => "1")
    end

    it "routes to #create" do
      post("/v1/attachments").should route_to("v1/attachments#create")
    end

    it "routes to #update" do
      put("/v1/attachments/1").should route_to("v1/attachments#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/v1/attachments/1").should route_to("v1/attachments#destroy", :id => "1")
    end

  end
end
