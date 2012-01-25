require '../mailgun.rb'

class EmailList
	def add
	end

	def grabAllEmails
		return Array.new
	end

end

describe EmailList, "" do
	it "should have a .add method" do
		emails = EmailList.new
		emails.add
	end

	it "should have .grabAllEmails" do
		emails = EmailList.new
		emails.grabAllEmails
	end
	
end

describe EmailList, '.grabAllEmails' do
	it 'should return an array' do
			emails = EmailList.new
			listOfEmails = emails.grabAllEmails
			listOfEmails.length.should eq(0)
	end
end


