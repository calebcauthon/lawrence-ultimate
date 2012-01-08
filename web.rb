require 'sinatra'
require 'haml'
require 'sass'

get '/' do
	haml :index
end

get '/style.css' do
	sass :style
end

get '/js/index.js' do
	File.read('js/index.js')
end
