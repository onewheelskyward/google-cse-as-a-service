require 'sinatra/base'
require 'onewheel-google'
require 'sinatra/config_file'

class App < Sinatra::Base
  register Sinatra::ConfigFile
  config_file 'config.yml'

  before do
    content_type 'application/json'
  end

  def check_auth(params)
    unless settings.token.include? params[:token] and settings.team_domain.include? params[:team_domain]
      puts "Token #{params[:token]} not found in #{settings.token} or #{params[:team_domain]} doesn't match #{settings.team_domain}"
      return false
    end
  end

  get '/google/' do
    halt 400, 'Auth failed.' if check_auth(params)

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

  get '/image/' do
    halt 400, 'Auth failed.' if check_auth(params)

    puts params[:response_url]

    result = OnewheelGoogle::search(params[:text], settings.cse_id, settings.api_key, 'high', image = true)

    {
      response_type: 'in_channel',
      text: result['items'][0]['link'],
    }.to_json
  end
end
