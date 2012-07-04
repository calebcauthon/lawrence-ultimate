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
	
	db = Mongo::Connection.new('ds033897.mongolab.com', 33897).db('heroku_app2357454')
	db.authenticate('ccauthon', 'ccauthon')   
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
	  db = Mongo::Connection.new('ds033897.mongolab.com', 33897).db('heroku_app2357454')
	db.authenticate('ccauthon', 'ccauthon')   
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
  db = Mongo::Connection.new('ds033897.mongolab.com', 33897).db('heroku_app2357454')
	db.authenticate('ccauthon', 'ccauthon')   
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
  db = Mongo::Connection.new('ds033897.mongolab.com', 33897).db('heroku_app2357454')
	db.authenticate('ccauthon', 'ccauthon')   
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
  db = Mongo::Connection.new('ds033897.mongolab.com', 33897).db('heroku_app2357454')
	db.authenticate('ccauthon', 'ccauthon')   
	coll = db.collection('people')
	people = coll.find({"team" => team})
	
	email = Array.new
	people.each do |person|
	  email.push person
	end
	
	email
end

def get_emails_for_team(team)
  db = Mongo::Connection.new('ds033897.mongolab.com', 33897).db('heroku_app2357454')
	db.authenticate('ccauthon', 'ccauthon')   
	coll = db.collection('people')
	@people = coll.find({"team" => team})
	
	email = Array.new
	@people.each do |person|
	  email.push person["full_name_and_email"]
	end
	
	email.join(",")
end

post '/email' do
  @@params = params
  
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

  item = items.select { |i| @@params[:to].include?(i.to) }[0]
  to_email = get_emails_for_team(item.team)
  from_email = item.from_email
  
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
  
  mail = Mail.deliver do
    to ""
    bcc to_email.force_encoding("binary").to_crlf
    from @@params[:from].force_encoding("binary").to_crlf
    reply_to from_email.force_encoding("binary").to_crlf
    subject @@params[:subject].force_encoding("binary").to_crlf
    text_part do
      body @@params[:text].force_encoding("binary").to_crlf
    end
    html_part do
      content_type 'text/html; charset=UTF-8'
      body @@params[:html].force_encoding("binary").to_crlf
    end
  end
end
