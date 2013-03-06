require 'sinatra'
require 'sinatra/contrib/all'
require 'haml'
require 'sass'
require 'mongo'
require 'curb' 
require './authentication.rb'
require './mailgun.rb'

enable :sessions

post '/email-preferences' do
	keep_on_list = params['keep_on_list'] == "yes"
	puts params
	
	@email_id = session[:email_id]
	doc = get_the_db_entry_for_this_email_id @email_id
	
	doc['opted_out'] = !keep_on_list;
	email_list.save doc
	
	get_email_preferences
end

get '/email-preferences' do
	get_email_preferences
end

def get_email_preferences
	@logged_in = session[:logged_in]
	@email_id = session[:email_id]
	doc = get_the_db_entry_for_this_email_id(@email_id)
	@email_address = doc['email_address']
	
	if(doc['opted_out'])
		@has_opted_out = true
	else
		@has_opted_out = false
	end
	
	haml :email_preferences, :layout => :bootstrap_template
end

post '/' do
	addToListOfUnverifiedSummerLeagueEmails(params['email_address'])
	@justSignedUp = true
	get_index
end

def getEmailStatusFromEmailId(emailID)
	coll = email_list
	begin 
		result = coll.find(:id => BSON::ObjectId(emailID)).next
		if(result['verified'] == true)
			return :verified
		else
			return :unverified
		end
	rescue StandardError => bang
		return :not_found
	end
	
	if(result.count > 0)
		return :unverified
	end	

end

get '/' do
	get_index
end

def get_index
	haml :index, :layout => :bootstrap_template
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


def email_list
	db = Mongo::Connection.new('staff.mongohq.com', 10025).db('app2382060')
	db.authenticate('heroku', 'heroku')	
	db.collection('email_list')
end

def aVerificationEmailHasBeenSentToThisEmailAddress(doc)
	return false unless !doc['emails']
	
	doc['emails'].each do |thisDoc| 
		if(thisDoc['type'].eql? "verification")
			return true
		end
	end
	return false
end

def thisEmailAddressHasBeenVerified(doc) 
	if(doc['verified'])
		return true
	else
		return false
	end
end

def createDbEntryShowingThatAVerificationEmailHasBeenSent(doc) 
	coll = email_list
	
	if(!doc['emails'])
		doc['emails'] = Array.new
	end
	
	doc['emails'].push({"type" => "verification", 'timestamp' => getTimestamp})
	coll.update({'_id' => doc['_id']}, doc)	
end

def get_the_db_entry_for_this_email_id(id)
	email_list.find({'_id' => BSON::ObjectId(id.to_s)}).next
end

def get_or_create_the_db_entry_for_this_email_address(email)
def get_or_create_the_db_entry_for_this_email_address(email)
	result = email_list.find({'email_address' => email}).first

  return result unless result.nil?
	
  document_id = email_list.insert({
                                    'email_address' => email,
                                    'timestamp' => getTimestamp,
                                    'verified' => false
                                  })
  email_list.find_one({:_id => BSON::ObjectId(document_id.to_s)})
end

def a_verification_email_needs_to_be_sent(doc)
	if(!thisEmailAddressHasBeenVerified(doc) && !aVerificationEmailHasBeenSentToThisEmailAddress(doc))
		return true
	else
		return false
	end
end

def addToListOfUnverifiedSummerLeagueEmails(email)
	@emailAddress = email
	
	doc = get_or_create_the_db_entry_for_this_email_address(email)
	if(a_verification_email_needs_to_be_sent(doc))
		sendVerificationEmail(email)
		createDbEntryShowingThatAVerificationEmailHasBeenSent(doc)					
		
		@accountWebkey = doc['_id'].to_s
		@emailSent = true
		@hasEmailConfirmationWaiting = true
		session[:logged_in] = true
		session[:email_id] = doc['_id']
	elsif(thisEmailAddressHasBeenVerified(doc))
		@alreadyVerified = true
	else
		@hasEmailConfirmationWaiting = true
	end
end


def sendVerificationEmail(email_address)
	api_url = 'https://api.mailgun.net/v2'
	api_key = 'key-31qllrfmv51h67b1nwoln0wjrd5qsuf9'

	id = get_the_object_id email_address, 'email_list'

	recipient = 'calebcauthon@gmail.com' #email_address
	sender = "'Lawrence Ultimate eTeam' <caleb@lawrenceultimate.com>"
	subject = 'Email Verification'
	body = "Thanks for joining the Lawrence Ultimate community!

Follow this link to verify your email address:
http://localhost:5000/verify/#{id}

Sincerely,
Lawrence Ultimate eTeam"
	
	Mailgun::init(api_key)
	MailgunMessage::send_text(sender, recipient, subject, body)
end

def get_the_object_id(email_address, collectionName)
	coll = email_list(collectionName)
	doc = coll.find({'email_address' => email_address}).next
	object_id = doc['_id'].to_s
	object_id
end

def markEmailAsVerified(doc_id)
	coll = email_list('email_list')
	doc = coll.find({'_id' => BSON::ObjectId(doc_id)}).next
	doc['verified'] = true
	coll.save(doc)
end



get '/verify/:email_id' do
	markEmailAsVerified(params['email_id'])
		
	session[:logged_in] = true
	session[:email_id] = params['email_id']

	haml :verify, :layout => :bootstrap_template
end

def getTimestamp
	DateTime.now.to_s
end

get '/style.css' do
	sass :style
end

get '/js/:file' do
	File.read("js/#{params['file']}")
end
