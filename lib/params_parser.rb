require 'active_support/core_ext/hash/conversions'
require 'action_dispatch/http/request'
require 'active_support/core_ext/hash/indifferent_access'

module ActionDispatch
  class ParamsParser
    def call(env)
      begin
        if params = parse_formatted_parameters(env)
          env["action_dispatch.request.request_parameters"] = params
        end
        @app.call(env)
      rescue Exception=>e
      error={:response=>:failure,:errors=>[{:code=>7002,:message=>"Bad request"}]}
      body=error.to_json 
      content_type="application/json"
      if env['HTTP_ACCEPT']=="application/xml"
        body=error.to_xml(:root=>:result) 
        content_type="application/xml"
      end
        [400,{'Content-Type'=>content_type},body]
      end
    end
  end
end