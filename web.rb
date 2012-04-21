require 'sinatra'
require 'sinatra/contrib/all'
require 'haml'
require 'sass'
require 'mongo'
require 'curb' 
require './authentication.rb'
require './mailgun.rb'

enable :sessions



get '/' do
	haml :index, :layout => :bootstrap_template
end

get '/summer-league-signup' do
	haml :signup, :layout => :bootstrap_template
end

get '/assets/js/:jsFile' do
	File.read("assets/js/#{params['jsFile']}")
end

get %r{([^\.]+)\.asdfcss} do
	File.read("assets/css/#{params[:captures].first}.css")
end

get '/about' do
	haml :about, :layout => :layout
end

get '/style.css' do
	sass :style
end

get '/js/:file' do
	File.read("js/#{params['file']}")
end
