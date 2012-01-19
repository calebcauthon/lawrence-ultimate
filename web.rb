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

get '/saved_emails' do
	coll = grabTheSavedEmailCollection
	@saved_emails = coll.find()

	haml :saved_emails
end

get '/saved_emails/details/:saved_email_id' do
	coll = grabTheSavedEmailCollection

	@id = params[:saved_email_id]
	@saved_email = coll.find(:_id => BSON::ObjectId(params[:saved_email_id])).next
	
  coll = grabTheEmailCollection
  @email_addresses = coll.find()

	haml :saved_email_details
end

get '/saved_emails/details/remove_email/:saved_email_id/:email_address_id' do
	saved_email_id = params[:saved_email_id]
	email_address_id = params[:email_address_id]

	saved_email_coll = grabTheSavedEmailCollection
	this_saved_email = saved_email_coll.find(:_id => BSON::ObjectId(saved_email_id)).next
	recipients = this_saved_email['recipients'].to_a

	email_to_remove = recipients.delete_if { |email| email['_id'] == BSON::ObjectId(email_address_id) }
	this_saved_email['recipients'] = recipients
	saved_email_coll.save(this_saved_email)

	show_details(saved_email_id)
end

def show_details(saved_email_id)
	coll = grabTheSavedEmailCollection

	@id = saved_email_id
	@saved_email = coll.find(:_id => BSON::ObjectId(saved_email_id)).next
	
  coll = grabTheEmailCollection
  @email_addresses = coll.find()

	haml :saved_email_details
end

post '/saved_emails/details/:saved_email_id' do
	saved_email_coll = grabTheSavedEmailCollection
	@id = params[:saved_email_id]
	@saved_email = saved_email_coll.find(:_id => BSON::ObjectId(params[:saved_email_id])).next
	
	if(params['subject'].nil? == false)
		@saved_email['subject'] = params['subject']
	end
	
	if(params['body'].nil? == false)
		@saved_email['body'] = params['body']
	end

	if(params['add'].nil? == false)
		new_id = params['new_email_address']
		coll = grabTheEmailCollection
		new_email = coll.find(:_id => BSON::ObjectId(new_id)).next

		@saved_email['recipients'].push(new_email)
	end

	saved_email_coll.save(@saved_email)
	
	if(params['send'] == '')
		@saved_email['sent'] = true;
		@saved_email['sent_timestamp'] = Time.now
		saved_email_coll.save(@saved_email)
	end
	
	coll = grabTheEmailCollection
  @email_addresses = coll.find()

	haml :saved_email_details
end

def grabTheEmailCollection
	db = Mongo::Connection.new('staff.mongohq.com', 10025).db('app2382060')
	db.authenticate('heroku', 'heroku')
	db.collection_names.each { |name| puts name }	
	coll = db.collection('emails')
	
	coll
end

def grabTheSavedEmailCollection
	db = Mongo::Connection.new('staff.mongohq.com', 10025).db('app2382060')
	db.authenticate('heroku', 'heroku')
	db.collection_names.each { |name| puts name }	
	coll = db.collection('saved_emails')
	
	coll
end

post '/signup' do
	coll = grabTheEmailCollection

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
	coll = grabTheEmailCollection
	@emails = coll.find()
	haml :notify
end

post '/notify' do
	message_body = params['message_body']
	
	selected_emails = Array.new

	if params['emails_selected'].nil? == false	
		params['emails_selected'].each_index do |i|
			if params['emails_selected'][i].eql? "on"
				selected_emails.push(params['email_addresses'][i])
			end
		end	
	end

	if params['send'] == ''
		selected_emails.each do |email_address|		
			send_email(email_address, message_body)
		end
		haml :notify_submit
	end

	if params['save_for_later'] == ''
		saved_email = { 'recipients' => selected_emails, 'body' => params['message_body'] }
		coll = grabTheSavedEmailCollection
		coll.insert(saved_email)
		haml :notify_save		
	end

	if params['add'] == ''
		email_address = params['new_email_address']
	end


end

get '/style.css' do
	sass :style
end

get '/js/index.js' do
	File.read('js/index.js')
end
