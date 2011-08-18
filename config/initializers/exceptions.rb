module ActionDispatch
  class ShowExceptions
    def render_exception(env, exception)
      error=[{:message=>'bad request',:code=>9001}]
      method='.to_json'
      method='.to_xml(:root=>"errors")' if env['HTTP_ACCEPT']=='application/xml'
      if exception.kind_of? ActionController::RoutingError
        render(404, eval("#{error}#{method}"))
      else
        render(500, 'Something went wrong')
      end
    end
  end
end