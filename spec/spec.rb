ENV['RACK_ENV'] = 'test'

require_relative '../app'
require 'rspec'
require 'rack/test'
require 'simplecov'
require 'coveralls'

Coveralls.wear!
SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
]

SimpleCov.start { add_filter '/spec.rb' }

RSpec.configure do |config|
  config.include Sinatra::Helpers
  config.include Rack::Test::Methods
end

def app
  App
end

describe 'The google-cse-as-a-service App' do
  before do
    allow(App).to receive(:check_auth).and_return(true)
    App.settings.tokens = ['x']
    App.settings.team_domains = ['woo']
    mock_result_json = File.open('spec/fixture.json').read
    allow(OnewheelGoogle).to receive(:search).and_return(JSON.parse mock_result_json)
  end

  it 'searches google' do
    # get '/google/?mgmg'
    # expect(last_response.status).to eq(400)
    get '/google?token=x&team_domain=woo&text=boop'
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq('{"response_type":"in_channel","text":"https://s-media-cache-ak0.pinimg.com/736x/4a/43/a4/4a43a4b6569cf8a197b6c9217de3f412.jpg","attachments":[{"text":"Cute Bug says Ohai | Ohai | Pinterest | So Cute and Animal: Cute Bug says Ohai: Funny"}]}')
  end
end