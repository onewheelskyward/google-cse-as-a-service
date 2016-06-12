ENV['RACK_ENV'] = 'test'

require_relative 'app'
require 'rspec'
require 'rack/test'

describe 'The google-cse-as-a-service App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it 'searches google' do
    get '/google/?mgmg'
    expect(last_response.status).to eq(400)
  end
end
