# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
admin=User.new(:first_name=>"Admin",:last_name=>"MLS",:email=>"admin@mls.com",:password=>"mls123",:password_confirmation=>"mls123")
admin.skip_confirmation!
admin.save
admin.update_attribute(:is_admin,true)
admin.ensure_authentication_token!

#Addition of Template,TemplateDefinition,CustomPage,CustomPageFields
sales_call_arrays=["Prospect's current situation","Business Development Goals","Desired next outcome","My relative strengths","My relative vulnerabilities","Related Categories","Customer Buying Process Step","Customer Next Step","Assistance to Navigate"]
board_paper_arrays=["Draft Resolution","Executive Summary","Background","Recommendation","Strategy Implications","Financial Implications","Risk Analysis","Corporate Governance and Compliance","Management Responsibility","CEO Signature","Sponsor Signature","Board Paper Prepared By"]
type='String'
#Template ----------------Note------------------------------------------------
note=Template.create(:name=>"Note")
note.template_definitions.create(:sequence=>1,:has_text_section=>true)
note.template_definitions.create(:sequence=>2,:has_attachment_section=>true)

#Template ----------------MeetingNote-----------------------------------
meeting_note=Template.create(:name=>"Meeting Note")
meeting_note.template_definitions.create(:sequence=>1,:has_topics_section=>true)
meeting_note.template_definitions.create(:sequence=>2,:has_text_section=>true)
meeting_note.template_definitions.create(:sequence=>3,:has_task_section=>true)

#Template ----------------SalesCallPlan-------------------------------------
sales_call_plan=Template.create(:name=>"Sales Call Plan")
sales_call_plan.template_definitions.create(:sequence=>1,:has_topics_section=>true)
sales_template_definitions=sales_call_plan.template_definitions.create(:sequence=>2)
sales_custom_page_fields=sales_template_definitions.create_custom_page
sales_template_definitions.update_attributes(:custom_page_id=>sales_custom_page_fields._id)
sales_call_arrays.each do |sales_call|
	sales_custom_page_fields.custom_page_fields.create(:field_name=>sales_call,:field_type=>type)
end
sales_call_plan.template_definitions.create(:sequence=>3,:has_text_section=>true)
sales_call_plan.template_definitions.create(:sequence=>4,:has_attachment_section=>true)
sales_call_plan.template_definitions.create(:sequence=>5,:has_task_section=>true)

#Template ----------------Board Papers------------------------------------
board_papers=Template.create(:name=>"Board Papers")
board_papers.template_definitions.create(:sequence=>1,:has_topics_section=>true)
board_papers_template_definitions=board_papers.template_definitions.create(:sequence=>2)
board_papers_custom_page_fields=board_papers_template_definitions.create_custom_page
board_papers_template_definitions.update_attributes(:custom_page_id=>board_papers_custom_page_fields._id)
board_paper_arrays.each do |board_paper|
	board_papers_custom_page_fields.custom_page_fields.create(:field_name=>board_paper,:field_type=>type)
end
board_papers.template_definitions.create(:sequence=>3,:has_text_section=>true)
board_papers.template_definitions.create(:sequence=>4,:has_attachment_section=>true)
board_papers.template_definitions.create(:sequence=>5,:has_task_section=>true)