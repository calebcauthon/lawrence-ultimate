require 'sinatra'
require 'sinatra/contrib/all'
require 'haml'
require 'sass'
require 'curb' 
require 'mail'
require 'csv'
require 'airbrake'
require File.join(File.dirname(__FILE__), 'database.rb')
require File.join(File.dirname(__FILE__), 'extensions.rb')
require File.join(File.dirname(__FILE__), 'team.rb')
require File.join(File.dirname(__FILE__), 'lib.rb')
require File.join(File.dirname(__FILE__), 'scores.rb')

$stdout.sync = true
enable :show_exceptions, :raise_errors, :sessions

use Airbrake::Rack

Airbrake.configure do |config|
  config.api_key = '665982ab7514b4ed09a2bf65c3110c7f'
end

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
	haml :signup_2013_SL, :layout => :bootstrap_template
end

def save_2013_signup(player)
end

post '/summer-league-signup' do
  name = 'yourname'
  email = 'youremail'
  height = 'yourheight'
  weight = 'yourweight'
  experience = 'yourexperience'
  partner = 'yourpartner'
  
  @player = {}
  @player['name'] = name
  @player['email'] = email
  @player['height'] = height
  @player['weight'] = weight
  @player['experience'] = experience
  @player['partner'] = partner
  
  save_2013_signup(@player)
  
  haml :signup_2013_SL_thanks, :layout => :bootstrap_template
end

get '/fall-league-signup' do
	haml :fall_league_signup, :layout => :bootstrap_template
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

get '/games' do
  @error = ""
  @scores = Scores.get_all_scores
  haml :games, :layout => :bootstrap_template
end

post '/games' do
  winner = params['winner']
  loser = params['loser']
  winning_score = params['winning_score'].to_i
  losing_score = params['losing_score'].to_i

  db = get_db
  coll = db.collection("teams")

  winning_team = coll.find_one("name" => winner)
  losing_team = coll.find_one("name" => loser)
  
  @error = ""
  if(winning_team.nil?)
    @error = "#{winner} not found"
    @scores = Scores.get_all_scores
    return haml :games, :layout => :bootstrap_template
  end
  
  if(losing_team.nil?)
    @error = "#{loser} not found"
    @scores = Scores.get_all_scores
    return haml :games, :layout => :bootstrap_template
  end
  
  win = { "name" => loser, "PF" => winning_score, "PA" => losing_score }
  if(winning_team['wins'].nil?)
    winning_team['wins'] = Array.new
  end
  winning_team['wins'].push(win)
  coll.save(winning_team)
  
  loss = { "name" => winner, "PF" => losing_score, "PA" => winning_score }
  if(losing_team['losses'].nil?)
    losing_team['losses'] = Array.new
  end
  losing_team['losses'].push(loss)
  coll.save(losing_team)
  
  @scores = Scores.get_all_scores
  haml :games, :layout => :bootstrap_template
end


get '/delete_score/:team_id/:score_id' do
  puts "tem 1aaa"
  score_id = params['score_id']
  team_id = params['team_id']
  
  result = "didnt find it"
  
  db = get_db
	coll = db.collection('teams')
	
	this_team = coll.find_one('_id' => BSON::ObjectId(team_id))
	wins = this_team['wins']
  
  new_wins = Array.new
  wins.each do |this_win|
    this_win_id = "#{this_win['name']}-#{this_win['PF']}-#{this_win['PA']}"
    if this_win_id != score_id
      new_wins.push(this_win)
    end
  end
  this_team['wins'] = new_wins
  coll.save(this_team)
end



post '/email' do
  to_email = get_emails_for_recipient(params[:to])
  from_email = params[:to].gsub(/@lists\.lawrenceultimate\.com/, "@lawrenceultimate.com")
  
  Mail.send_email({
    "to" => "",
    "bcc" => to_email.encode_for_email,
    "from" => params[:from].encode_for_email,
    "reply_to" => from_email.encode_for_email,
    "subject" => params[:subject].encode_for_email,
    "text" => params[:text].encode_for_email,
    "html" => params[:html].encode_for_email
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

get '/airbrake_test' do
  puts "this should throw an airbrake error"
  dog ={}
  dog.airbrake_is_neat()
end

get '/enter_score' do
  Scores.add_score(params[:winner], params[:loser], params[:winning_score].to_i, params[:losing_score].to_i)
  haml :scores, :layout => :bootstrap_template
end
