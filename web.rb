require 'sinatra'
require 'sinatra/contrib/all'
require 'haml'
require 'sass'
require 'curb' 

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
		loser.losses = loser.losses + 1
		loser.points_for = loser.points_for + points_against
		loser.points_against = loser.points_against + points_for

		@wins = @wins + 1
		@points_for = @points_for + points_for
		@points_against = @points_against + points_against
	end

end

get '/' do
	haml :index, :layout => :bootstrap_template
end

get '/standings' do
	@teams = Array.new
	
	@pink = Team.new
	@pink.name = "Pink"

	@blue = Team.new
	@blue.name = "Blue"

	@red = Team.new
	@red.name = "Red"

	@white = Team.new
	@white.name = "White"

	@black = Team.new
	@black.name = "Black"

	@yellow = Team.new
	@yellow.name = "Yellow"

	@orange = Team.new
	@orange.name = "Orange"

	@green = Team.new
	@green.name = "Green"

	@pink.defeated @blue,17,8
	@white.defeated @red,17,13
	@black.defeated @yellow,17,8
	@orange.defeated @green,17,12

	@red.defeated @black,15,12
	@blue.defeated @green,15,12
	@white.defeated @pink,17,15
	@orange.defeated @yellow,15,10
	
	@teams.push(@blue)
	@teams.push(@red)	
	@teams.push(@yellow)
	@teams.push(@green)
	@teams.push(@yellow)
	@teams.push(@pink)
	@teams.push(@black)
	@teams.push(@orange)

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
