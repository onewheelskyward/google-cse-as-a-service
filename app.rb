require 'sinatra/base'
require 'onewheel-google'
require 'sinatra/config_file'

class App < Sinatra::Base

  # Copy the config file from dist if it does not exist
  config_file = File.dirname(__FILE__) + '/config.yml'
  unless File.exist? config_file
    puts 'Auto-copying config distribution file to active config'
    system "cp #{File.dirname(__FILE__)}/config/config.yml.dist #{config_file}"
  end

  register Sinatra::ConfigFile
  config_file 'config.yml'

  before do
    content_type 'application/json'
  end

  def check_auth(params)
    unless settings.tokens.include? params[:token] and settings.team_domains.include? params[:team_domain]
      puts "Token #{params[:token]} not found in #{settings.tokens} or #{params[:team_domain]} doesn't match #{settings.team_domains}"
      false
    end
    true
  end

  def run_search(image = false)
    result = OnewheelGoogle::search(params[:text], settings.cse_id, settings.api_key, 'high', image)

    unless result
      halt 500, '{"message": "search failed to return results."}'
    end

    result
  end

  get '/google*' do
    halt 400, '{"message": "Auth failed."}' unless check_auth(params)

    puts params[:response_url]

    result = run_search

    {
      response_type: 'in_channel',
      text: result['items'][0]['link'],
      attachments: [{
        text: "#{result['items'][0]['title']}: #{result['items'][0]['snippet']}"
      }]
    }.to_json
  end

  get '/image*' do
    halt 400, 'Auth failed.' unless check_auth(params)

    puts params[:response_url]

    result = run_search(image = true)

    {
      response_type: 'in_channel',
      text: result['items'][0]['link'],
    }.to_json
  end

  get '/giphy*' do
    halt 400, 'Auth failed.' unless check_auth(params)

    puts params[:response_url]

    params[:text] = "giphy #{params[:text]}"
    result = run_search(image = true)

    # do some math on the image to make sure we get the animated gif here.
    {
      response_type: 'in_channel',
      text: result['items'][0]['link'],
    }.to_json
  end
end
