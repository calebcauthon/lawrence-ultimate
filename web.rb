require 'sinatra'
require 'haml'
require 'sass'
require 'mongo'
require 'curb' 
require './mailgun.rb'
require './authentication.rb'

get '/' do
	haml :index, :layout => :layout
end

get '/about' do
	haml :about, :layout => :layout
end

get '/signup' do
		haml :signup
do

post '/signup' do
	coll = grabTheEmailCollection

	doc = { 'email_address' => params['email_address'] }
	coll.insert(doc)
	
	haml :signup
end

get '/style.css' do
	sass :style
end

get '/js/index.js' do
	File.read('js/index.js')
end
