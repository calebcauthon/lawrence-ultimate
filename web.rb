require 'sinatra'
require 'sinatra/contrib/all'
require 'haml'
require 'sass'
require 'wufoo' 
require 'pp'

enable :sessions



get '/' do
	haml :index, :layout => :bootstrap_template
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

get '/status' do

	session = Wufoo.login("lawrenceultimate", "BVQA-BKGS-XPOY-K5FG")
	form = session.forms.first
	
	needle = params[:name]

	@foundThePerson = false
	if(needle.eql?(""))
		@isASearch = false
	else
		@isASearch = true
	end

	form.entries.each do |entry|
		first_name = entry.attrs["Field1"]
		last_name = entry.attrs["Field2"]
		partner = entry.attrs["Field116"]
		height = entry.attrs["Field111"]
		shirt = entry.attrs["Field109"]
		gender = entry.attrs["Field6"]
		
		if(partner.eql?("I'm signing up by myself"))
			hasAPartner = false
		else
			hasAPartner = true
		end
		
		if(gender.eql?("Male"))
			isMale = true
		else
			isMale = false
		end
		
		name = "#{first_name} #{last_name}"
		if(name.eql?(needle))
		
			if(hasAPartner)
				@nameOfThePartner = partner
			end
			
			@name = name			
			@hasAPartner = hasAPartner
			@shirt = shirt
			@height = height
			@foundThePerson = true
		end		
	end
	
	@needle = needle
	haml :status, :layout => :bootstrap_template
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
