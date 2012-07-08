require 'mongo'

def get_db
  db = Mongo::Connection.new(settings.db_uri, settings.db_port).db(settings.db_name)
	db.authenticate(settings.db_username, settings.db_pw)   
	db
end