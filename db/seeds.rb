# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)
admin=User.new(:first_name=>"Admin",:last_name=>"MLS",:email=>"admin@mls.com",:password=>"mls123",:password_confirmation=>"mls123")
admin.is_admin=true
admin.skip_confirmation!
admin.save
admin.ensure_authentication_token!