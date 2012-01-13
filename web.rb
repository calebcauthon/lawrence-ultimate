require 'sinatra'
require 'haml'
require 'sass'
require 'mongo'
require 'curb' 
require './mailgun.rb'

get '/' do
	haml :index, :layout => :layout
end

get '/about' do
	haml :about, :layout => :layout
end

def get_emails
	db = Mongo::Connection.new('staff.mongohq.com', 10025).db('app2382060')
	db.authenticate('heroku', 'heroku')
	db.collection_names.each { |name| puts name }	
	coll = db.collection('emails')
	
	coll
end

post '/signup' do
	coll = get_emails

	doc = { 'email_address' => params['email_address'] }
	coll.insert(doc)
	
	haml :signup
end

def send_email(email_address, email_body)
	Mailgun::init("key-31qllrfmv51h67b1nwoln0wjrd5qsuf9")
	MailgunMessage::send_text("caleb@lawrenceultimate.com",
                          email_address,
                          "email is pretty neat",
                          email_body)
end

get '/notify' do
	coll = get_emails	
	@emails = coll.find()
	haml :notify
end

post '/notify' do
	message_body = params['message_body']
	
	selected_emails = Array.new
	
	params['emails_selected'].each_index do |i|
		if params['emails_selected'][i].eql? "on"
			selected_emails.push(params['email_addresses'][i])
		end
	end	

	selected_emails.each do |email_address|
		send_email(email_address, message_body)
	end


	haml :notify_submit
end

get '/style.css' do
	sass :style
end

get '/js/index.js' do
	File.read('js/index.js')
end
