require 'sinatra/base'
require 'onewheel-google'
require 'sinatra/config_file'

class App < Sinatra::Base

  # Copy the config file from dist if it does not exist
  config_file = File.dirname(__FILE__) + '/config.yml'
  unless File.exist? config_file
    puts 'Auto-copying config distribution file to active config'
    system "cp #{File.dirname(__FILE__)}/config.yml.dist #{config_file}"
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

  def run_search(query, image = false)
    result = OnewheelGoogle::search(query, settings.cse_id, settings.api_key, 'high', image)

    unless result
      halt 500, '{"message": "search failed to return results."}'
    end

    result
  end

  get '/google*' do
    halt 400, '{"message": "Auth failed."}' unless check_auth(params)

    puts params[:response_url]

    result = run_search params[:text]

    { response_type: 'in_channel',
      text: result['items'][0]['link'],
      attachments: [{
        text: "#{result['items'][0]['title']}: #{result['items'][0]['snippet']}"
      }]
    }.to_json
  end

  get '/image*' do
    halt 400, 'Auth failed.' unless check_auth(params)

    puts params[:response_url]

    result = run_search(params[:text], image = true)

    { response_type: 'in_channel',
      text: result['items'][0]['link'],
    }.to_json
  end

  get '/giphy*' do
    halt 400, 'Auth failed.' unless check_auth(params)

    puts params[:response_url]

    query = 'giphy ' + params[:text].to_s
    result = run_search(query, image = true)
    # Hack this so we can return a new giphy each time.
    image = nil

    if result
      result['items'].each do |r|
        puts r['mime']
        if r['mime'] == 'image/gif'
          image = r
          break
        end
      end
    end

    # do some math on the image to make sure we get the animated gif here.
    if image
      if image['link'][/200_s.gif$/]
        image['link'].gsub! /200_s.gif/, 'giphy.gif'
      end

      { response_type: 'in_channel',
        text: image['link'],
      }.to_json
    end
  end
end
