# Monkeypatch for resmap api
require "resource_map/api"
module ResourceMap
  class Api
    def process_response(response)
      response
    end
  end
end
