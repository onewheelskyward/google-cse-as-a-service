require 'sinatra/base'
require 'onewheel-google'
require 'sinatra/config_file'

class App < Sinatra::Base
  register Sinatra::ConfigFile
  config_file 'config.yml'

  get '/google/' do
    content_type 'application/json'

    unless params[:token] == settings.token
      and params[:team_domain] == settings.team_domain
    end

    puts params[:response_url]

    result = OnewheelGoogle::search(params[:text], settings.cse_id, settings.api_key, 'high')

    {
      response_type: 'in_channel',
      text: result['items'][0]['link'],
      attachments: [{
        text: "#{result['items'][0]['title']}: #{result['items'][0]['snippet']}"
      }]
    }.to_json
  end
end
