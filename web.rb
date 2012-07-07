require 'sinatra'
require 'sinatra/contrib/all'
require 'haml'
require 'sass'
require 'curb' 
require 'mongo'
require 'mail'
require 'csv'
require 'airbrake'
require 'smoke_monster'

enable :sessions
Airbrake.configure do |config|
  config.api_key = '665982ab7514b4ed09a2bf65c3110c7f'
end

use Airbrake::Rack

$stdout.sync = true

set :environment, :production

puts "Using environment: #{settings.environment}"

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



def get_db
  db = Mongo::Connection.new(settings.db_uri, settings.db_port).db(settings.db_name)
	db.authenticate(settings.db_username, settings.db_pw)   
	db
end




class String

  def encode_for_email
    self.force_encoding('ISO-8859-1').encode!('UTF-8',invalid: :replace,undef: :replace,replace: '?')
  end
  
  def encode_for_html
    self.gsub!(/</, '&lt;')
    self.gsub!(/>/, '&gt;')
  end
  
end

class Team
	include Comparable
	attr_accessor :name, :wins, :losses, :points_for, :points_against

	def <=>(other)
		if(@wins > other.wins)
			return -1
		elsif(@wins < other.wins)
			return 1
		else
			if(@points_for > other.points_for)
				return -1
			elsif(@points_for < other.points_for)
				return 1
			else
				return 0
			end
		end
	end	

	def initialize 
		@wins = 0
		@losses = 0
		@points_for = 0
		@points_against = 0
	end
	
	def defeated(loser, points_for, points_against)
		@wins = @wins + 1
		@points_for = @points_for + points_for
		@points_against = @points_against + points_against
	end

	def lost_to(winner, points_for, points_against)
		@losses = @losses + 1
		@points_for = @points_for + points_against
		@points_against = @points_against + points_for
	end

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

get '/parse_emails' do
  db = get_db
	coll = db.collection('people')
	
  CSV.foreach("../lusl/public/emails.csv") do |row|
    basic_email_address = row[0]
    full_name_and_email = row[1]
    full_name = row[2]
    name_and_team = row[3]
    team = row[4]
    
    doc = {"team" => team, "email_address" => basic_email_address, "full_name" => full_name, "full_name_and_email" => full_name_and_email}
    
    coll.insert(doc)
    
  end
  haml :parse_emails, :layout => :bootstrap_template
end

get '/email' do
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
end

def get_emails_object_for_team(team)
  db = get_db 
	coll = db.collection('people')
	people = coll.find({"team" => team})
	
	email = Array.new
	people.each do |person|
	  email.push person
	end
	
	email
end

def get_emails_for_team(team)
  db = get_db
	coll = db.collection('people')
	@people = coll.find({"team" => team})
	
	email = Array.new
	@people.each do |person|
	  email.push person["full_name_and_email"]
	end
	
	email.join(",")
end

def get_emails_for_email_list(list)
  db = get_db
	coll = db.collection('people')
	@people = coll.find({"email-list" => list})
	
	email = Array.new
	@people.each do |person|
	  email.push person["full_name_and_email"]
	end
	
	email.join(",")
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

def get_emails_for_recipient(to) 
  # remove the @ symbol and everything after it (e.g., "caleb@lawrenceultimate.com" => "caleb")
  list = to.gsub(/@.+/, "@lawrenceultimate.com").gsub(/[^<]+</, "")
  

  to_email = get_emails_for_email_list(list)

  puts "turned #{to} into #{list} into #{to_email}"

  to_email
  
end

def get_reply_to_for_email_list(to) 
  # need to add gem smoke_monster for this
  items = [:to, :team, :from_email].to_objects {
    [
      ["blue@", "BLUE", "Blue Team <blue@lawrenceultimate.com>"],
      ["red@", "RED", "Red Team <red@lawrenceultimate.com>"],
      ["white@", "WHITE", "White Team <white@lawrenceultimate.com>"],
      ["black@", "BLACK", "Black Team <black@lawrenceultimate.com>"],
      ["orange@", "ORANGE", "Orange Team <orange@lawrenceultimate.com>"],
      ["green@", "GREEN", "Green Team <green@lawrenceultimate.com>"],   
      ["yellow@", "YELLOW", "Yellow Team <yellow@lawrenceultimate.com>"],
      ["pink@", "PINK", "Pink Team <pink@lawrenceultimate.com>"],
      ["test@", "TEST", "Test Team <test@lawrenceultimate.com>"]
    ]
  }  

  item = items.select { |i| to.include?(i.to) }[0]
  if(item.nil?)
    return "no emails found for #{to}"
  end
  from_email = item.from_email
  from_email
end

post '/email' do
  puts params.to_s

  to_email = get_emails_for_recipient(params[:to])
  from_email = params[:to]
  
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

