require 'sinatra'
require 'sinatra/contrib/all'
require 'haml'
require 'sass'
require 'curb' 
require 'mongo'
require 'mail'
require 'csv'

enable :sessions


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
	
	haml :teams, :layout => :bootstrap_template
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
	
  haml :manage_email, :layout => :bootstrap_template
end

def get_blue_emails
  db = Mongo::Connection.new('ds033897.mongolab.com', 33897).db('heroku_app2357454')
	db.authenticate('ccauthon', 'ccauthon')   
	coll = db.collection('people')
	@people = coll.find({"team" => "TEST"})
	
	email = Array.new
	@people.each do |person|
	  email.push person["full_name_and_email"]
	end
	
	email.join(",")
end

post '/email' do
  @@params = params
  
  blue_email = get_blue_emails
  red_email = "calebcauthon+red@gmail.com"
  green_email = "calebcauthon+green@gmail.com"
  white_email = "calebcauthon+white@gmail.com"
  orange_email = "calebcauthon+orange@gmail.com"
  green_email = "calebcauthon+green@gmail.com"
  yellow_email = "calebcauthon+yellow@gmail.com"
  pink_email = "calebcauthon+pink@gmail.com"
  
  if(@@params[:to].match("blue@") != nil)
    to_email = blue_email
    from_email = "Blue Team <blue@lawrenceultimate.com>"
  elsif(@@params[:to].match("red@") != nil)
    to_email = red_email
  elsif(@@params[:to].match("white@") != nil)
    to_email = white_email
  elsif(@@params[:to].match("black@") != nil)
    to_email = black_email
  elsif(@@params[:to].match("orange@") != nil)
    to_email = orange_email
  elsif(@@params[:to].match("green@") != nil)
    to_email = green_email
  elsif(@@params[:to].match("yellow@") != nil)
    to_email = yellow_email
  elsif(@@params[:to].match("pink@") != nil)
    to_email = pink_email
  end if
  
  
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
    bcc to_email
    from from_email
    subject params[:subject]
    text_part do
      body @@params[:text]
    end
    html_part do
      content_type 'text/html; charset=UTF-8'
      body @@params[:html]
    end
  end
end

blue_team_emails = []
blue_team_emails.push("calebcauthon@gmail.com");
blue_team_emails.push("caleb@lawrenceultimate.com");

get '/blue-team-email' do
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
    to blue_team_emails.join(",")
    from 'Blue Team <blue@listslawrenceultimate.com>'
    subject 'ruby emails!'
    text_part do
      body 'Hello world in text'
    end
    html_part do
      content_type 'text/html; charset=UTF-8'
      body '<b>Hello world in HTML</b>'
    end
  end
end
