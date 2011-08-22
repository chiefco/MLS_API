require 'spec_helper'

describe "v1/bookmarks/new.html.erb" do
  before(:each) do
    assign(:v1_bookmark, stub_model(V1::Bookmark,
      :name => "MyString"
    ).as_new_record)
  end

  it "renders new v1_bookmark form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => v1_bookmarks_path, :method => "post" do
      assert_select "input#v1_bookmark_name", :name => "v1_bookmark[name]"
    end
  end
end
