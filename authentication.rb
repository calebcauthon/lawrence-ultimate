use Rack::Auth::Basic, "Restricted Area" do |username, password|
	[username, password] == ['lawrence-user', 'lawrence-usr']
end


