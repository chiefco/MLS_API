require 'active_support/core_ext/hash/conversions'
require 'action_dispatch/http/request'
require 'active_support/core_ext/hash/indifferent_access'

module ActionDispatch
  class ParamsParser
    def call(env)
      begin
        if params = parse_formatted_parameters(env)
          env["action_dispatch.request.request_parameters"] = params
          @app.call(env)
        end
      rescue Exception=>e
        [400,{'Content-Type'=>'application/json'},{:message=>"Invalid request"}.to_json]
      end
    end
  end
end