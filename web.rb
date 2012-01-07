require 'sinatra'
require 'haml'
require 'sass'

get '/' do
	haml :index
end

get '/style.css' do
	sass :style
end

