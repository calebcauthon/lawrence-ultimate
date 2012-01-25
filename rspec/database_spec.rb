require 'mongo'

class HerokuDatabase
	def grabCollection(collectionName)
		db = Mongo::Connection.new('staff.mongohq.com', 10025).db('app2382060')
		db.authenticate('heroku', 'heroku')
		db.collection_names.each { |name| puts name }	
		coll = db.collection('emails')
		coll
	end
end

describe HerokuDatabase, "" do
	it 'should exist' do
	end

	it 'should have a grabCollection method' do
		db = HerokuDatabase.new
		db.grabCollection('test.emails')
	end
end

describe HerokuDatabase, '.grabCollection' do
	it 'should return a collection' do
		db = HerokuDatabase.new
		theCollection = db.grabCollection('test.emails')
		theCollection.class.to_s.should eq('Mongo::Collection')
	end

	it 'should return a zero length collection when theres nothing there' do
		db = HerokuDatabase.new
		theCollection = db.grabCollection('test.emails')
		puts theCollection.to_a
		theCollection.to_a.length.should eq(0)

	end
end

