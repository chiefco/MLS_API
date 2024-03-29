require 'json'
module Rack
  class ValidateHeader
    CONTENT_TYPE = %w{application/x-www-form-urlencoded application/xml application/json}
    ALLOWED_METHODS = %w{GET PUT POST DELETE}
    ERROR_RESPONSE=[400,{'Content-Type' => CONTENT_TYPE.last }, [{'errors' =>[{:message=>"Invalid headers",:code=>9000}]}.to_json]]

    def initialize(app, options = {})
      @app = app
    end

    def call(env)
      dup._call(env)
    end

    def _call(env)
      #~ content_type = Rack::Request.new(env).media_type
      env['HTTP_ACCEPT']="application/json" if env['HTTP_ACCEPT']!="application/xml"
      valid_request?(env) ? @app.call(env) : ERROR_RESPONSE
    end

    def valid_request?(env)
      content_type = Rack::Request.new(env).media_type
      ALLOWED_METHODS.include?(env['REQUEST_METHOD'])
    end
  end
end
