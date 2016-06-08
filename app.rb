require 'sinatra/base'
require 'onewheel-google'
require 'sinatra/config_file'

class App < Sinatra::Base
  register Sinatra::ConfigFile
  config_file 'config.yml'

  get '/' do
    # content_type 'application/json'
    result = OnewheelGoogle::search('google', settings.cse_id, settings.api_key, 'high')
    "#{result['items'][0]['link']} #{result['items'][0]['title']}: #{result['items'][0]['snippet']}"
  end
end
