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

describe V1::AttachmentsController do

  # This should return the minimal set of attributes required to create a valid
  # V1::Attachment. As you add validations to V1::Attachment, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {}
  end

  describe "GET index" do
    it "assigns all v1_attachments as @v1_attachments" do
      attachment = V1::Attachment.create! valid_attributes
      get :index
      assigns(:v1_attachments).should eq([attachment])
    end
  end

  describe "GET show" do
    it "assigns the requested v1_attachment as @v1_attachment" do
      attachment = V1::Attachment.create! valid_attributes
      get :show, :id => attachment.id.to_s
      assigns(:v1_attachment).should eq(attachment)
    end
  end

  describe "GET new" do
    it "assigns a new v1_attachment as @v1_attachment" do
      get :new
      assigns(:v1_attachment).should be_a_new(V1::Attachment)
    end
  end

  describe "GET edit" do
    it "assigns the requested v1_attachment as @v1_attachment" do
      attachment = V1::Attachment.create! valid_attributes
      get :edit, :id => attachment.id.to_s
      assigns(:v1_attachment).should eq(attachment)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new V1::Attachment" do
        expect {
          post :create, :v1_attachment => valid_attributes
        }.to change(V1::Attachment, :count).by(1)
      end

      it "assigns a newly created v1_attachment as @v1_attachment" do
        post :create, :v1_attachment => valid_attributes
        assigns(:v1_attachment).should be_a(V1::Attachment)
        assigns(:v1_attachment).should be_persisted
      end

      it "redirects to the created v1_attachment" do
        post :create, :v1_attachment => valid_attributes
        response.should redirect_to(V1::Attachment.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved v1_attachment as @v1_attachment" do
        # Trigger the behavior that occurs when invalid params are submitted
        V1::Attachment.any_instance.stub(:save).and_return(false)
        post :create, :v1_attachment => {}
        assigns(:v1_attachment).should be_a_new(V1::Attachment)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        V1::Attachment.any_instance.stub(:save).and_return(false)
        post :create, :v1_attachment => {}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested v1_attachment" do
        attachment = V1::Attachment.create! valid_attributes
        # Assuming there are no other v1_attachments in the database, this
        # specifies that the V1::Attachment created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        V1::Attachment.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => attachment.id, :v1_attachment => {'these' => 'params'}
      end

      it "assigns the requested v1_attachment as @v1_attachment" do
        attachment = V1::Attachment.create! valid_attributes
        put :update, :id => attachment.id, :v1_attachment => valid_attributes
        assigns(:v1_attachment).should eq(attachment)
      end

      it "redirects to the v1_attachment" do
        attachment = V1::Attachment.create! valid_attributes
        put :update, :id => attachment.id, :v1_attachment => valid_attributes
        response.should redirect_to(attachment)
      end
    end

    describe "with invalid params" do
      it "assigns the v1_attachment as @v1_attachment" do
        attachment = V1::Attachment.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        V1::Attachment.any_instance.stub(:save).and_return(false)
        put :update, :id => attachment.id.to_s, :v1_attachment => {}
        assigns(:v1_attachment).should eq(attachment)
      end

      it "re-renders the 'edit' template" do
        attachment = V1::Attachment.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        V1::Attachment.any_instance.stub(:save).and_return(false)
        put :update, :id => attachment.id.to_s, :v1_attachment => {}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested v1_attachment" do
      attachment = V1::Attachment.create! valid_attributes
      expect {
        delete :destroy, :id => attachment.id.to_s
      }.to change(V1::Attachment, :count).by(-1)
    end

    it "redirects to the v1_attachments list" do
      attachment = V1::Attachment.create! valid_attributes
      delete :destroy, :id => attachment.id.to_s
      response.should redirect_to(v1_attachments_url)
    end
  end

end
