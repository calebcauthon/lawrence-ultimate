require 'sinatra'
require 'sinatra/contrib/all'
require 'haml'
require 'sass'
require 'curb' 
require 'mail'
require 'csv'
require 'airbrake'
require 'smoke_monster'
require File.join(File.dirname(__FILE__), 'database.rb')
require File.join(File.dirname(__FILE__), 'extensions.rb')
require File.join(File.dirname(__FILE__), 'team.rb')
require File.join(File.dirname(__FILE__), 'lib.rb')


enable :sessions
Airbrake.configure do |config|
  config.api_key = '665982ab7514b4ed09a2bf65c3110c7f'
end

use Airbrake::Rack

$stdout.sync = true

configure :development do
  set :db_uri, 'ds033797.mongolab.com'
  set :db_port, 33797
  set :db_name, 'lusl-dev'
  set :db_username, 'ccauthon'
  set :db_pw, 'ccauthon'
end

configure :production do
  set :db_uri, 'ds033897.mongolab.com'
  set :db_port, 33897
  set :db_name, 'heroku_app2357454'
  set :db_username, 'ccauthon'
  set :db_pw, 'ccauthon'
end

get '/' do
	haml :index, :layout => :bootstrap_template
end

get '/full_schedule' do
	haml :full_schedule, :layout => :bootstrap_template
end

get '/standings' do
	@teams = Array.new
	
	db = get_db
	coll = db.collection('teams')

	@teams_list = coll.find()
	@teams_list.each do |team|
		this_team = Team.new
		this_team.name = team['name']

		wins = team['wins'] || []
		wins.each do |this_win|
			this_team.defeated this_win['name'],this_win['PF'],this_win['PA']
		end

		losses = team['losses'] || []
		losses.each do |this_loss|
			this_team.lost_to this_loss['name'],this_loss['PF'],this_loss['PA']
		end

		@teams.push(this_team)
	end
	
	@teams.sort!
	haml :standings, :layout => :bootstrap_template
end

get '/teams' do
	db = get_db
	coll = db.collection('people')
	@people = coll.find
	
	@blue = get_emails_object_for_team("BLUE")
	@green = get_emails_object_for_team("GREEN")
	@white = get_emails_object_for_team("WHITE")
	@red = get_emails_object_for_team("RED")
	@black = get_emails_object_for_team("BLACK")
	@yellow = get_emails_object_for_team("YELLOW")
	@pink = get_emails_object_for_team("PINK")
	@orange = get_emails_object_for_team("ORANGE")
	
	haml :manage_email, :layout => :bootstrap_template
	
	#haml :teams, :layout => :bootstrap_template
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

def send_email(options)
  Mail.defaults do 
    delivery_method :smtp, 
    { 
    :address   => "smtp.sendgrid.net",
    :port      => 587,
    :domain => "lawrenceultimate.com",
    :user_name => "app2357454@heroku.com",
    :password  => "9dtx7amf",
    :authentication => 'plain',
    :enable_starttls_auto => true }
  end
  
  if(settings.environment == :development)
    options['html'] = "Email would have gone to: [#{options['to'].encode_for_html}] and bcc'd [#{options['bcc'].encode_for_html}] -- \n<br /><br />  #{options['html']}"
    options['to'] = "calebcauthon+devlist@gmail.com"
    options['bcc'] = ""
    options['subject'] = "dev: #{options['subject']}"
  end
  
  mail = Mail.deliver do
    to options['to']
    bcc options['bcc']
    from options['from']
    reply_to options['reply_to']
    subject options['subject']
    text_part do
      body options['text']
    end
    html_part do
      content_type 'text/html; charset=UTF-8'
      body options['html']
    end
  end
end


post '/email' do
  to_email = get_emails_for_recipient(params[:to])
  from_email = params[:to].gsub(/@lists\.lawrenceultimate\.com/, "@lawrenceultimate.com")
  
  send_email({
    "to" => "",
    "bcc" => to_email.encode_for_email,
    "from" => params[:from].encode_for_email,
    "reply_to" => from_email.encode_for_email,
    "subject" => params[:subject].encode_for_email,
    "text" => params[:text].encode_for_email,
    "html" => params[:html].encode_for_email
  })
  
  send_email({
    "to" => "calebcauthon+cc@gmail.com",
    "bcc" => "",
    "from" => params[:from].encode_for_email,
    "reply_to" => from_email.encode_for_email,
    "subject" => "bcc'ing",
    "text" => "an email was sent!",
    "html" => "an email was sent!"
  })
end

post '/remove-from-list' do
  list = params[:list]
  guid = params[:player_guid]
  
  db = get_db
  coll = db.collection("people")
  person = coll.find_one(:_id => BSON::ObjectId(guid))

  person["email-list"].delete_if do |item|
    item == list
  end
  
  coll.save(person)
  
  "ok"
end

post '/add-to-list' do
  list = params[:list]
  guid = params[:player_guid]
  
  db = get_db
  coll = db.collection("people")
  person = coll.find_one(:_id => BSON::ObjectId(guid))
  
  if(person["email-list"].nil?)
    person["email-list"] = Array.new
  end
  
  person["email-list"].push(list)
  
  coll.save(person)
  "ok"
end

get '/players' do
  @list_to_search_for = params[:q]
  db = get_db
  coll = db.collection("people")
  @players = coll.find({ "$or" => [ {"email-list" => @list_to_search_for}, {"team" => @list_to_search_for} ] })
  
  haml :players, :layout => :bootstrap_template
end

