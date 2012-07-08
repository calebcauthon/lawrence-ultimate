require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Sinatra App" do
  it "should respond to GET" do
    get '/'
    last_response.should be_ok
  end
  
  
  def send_email
    "ok"
  end
  it "should be able to over write the send_email method" do
    send_email.should == "ok"
  end
  
  module Mail 
    @@options
    def self.options
      @@options
    end
    def self.send_email(options)
      @@options = options
    end
  end
  
  it "should response to POST /email" do
    post '/email', :to => "calebcauthon@gmail.com", :from => "from@gmail.com", :subject => "subject", :text => "text", :html => "html"
    last_response.should be_ok
    
    Mail.options["to"].should == ""
  end
  
  it "should send an email bcc'ing caleb-blue@lawrenceultimate.com if blue@lawrenceultimate.com is the to address" do
    list = "blue"
    to = "#{list}@lawrenceultimate.com"
    expected_to = "caleb-blue@lawrenceultimate.com"
    
    person = {"full_name_and_email" => expected_to, "email-list" => list}
    db = get_db
    coll = db.collection("people")
    coll.remove({"email-list" => list})
    coll.save(person)
    
    post '/email', :to => "#{to}", :from => "from@gmail.com", :subject => "subject", :text => "text", :html => "html"
      
    # clean up
    coll.remove(person)
    
    Mail.options["bcc"].should == expected_to
  end
  
  
end
describe "get_emails_for_recipient" do
  it "should exist" do
    get_emails_for_recipient ""
  end
  it "should return 1 result for asdf@lawrenceultimate.com" do
    email_list = "asdf"
    to = "#{email_list}@lawrenceultimate.com"
    
    expected_result = "caleb-asdf@lawrenceultimate.com"
    
    person = {"email-list" => email_list, "full_name_and_email" => expected_result}
    db = get_db
    coll = db.collection("people")
    coll.remove({"email-list" => email_list})
    coll.save(person)
    
    result = get_emails_for_recipient(to)
    
    # clean up
    coll.remove(person)
    
    result.should == expected_result
  end
end
describe "Mailing List" do
  it "should have a get_emails_for_email_list method" do
    MailingList.get_emails_for_email_list ""
  end
  it "should be using the dev database" do
    settings.db_name.should == "lusl-dev"
  end
  it "should return an empty string for a list with no people in it" do
    MailingList.get_emails_for_email_list("xxx").should == ""
  end 
  it "should remove all people with xxx as their email list" do
    db = get_db
    coll = db.collection("people")
    coll.remove({"email-list" => "xxx"})
    
    result = coll.find({"email-list" => "xxx"})
    result.count.should == 0
  end
  it "should add and remove a person" do
    db = get_db
    coll = db.collection("people")
    
    person = {"full_name_and_email" => "test@lawrenceultimate.com", "email-list" => "xxx"}
    coll.save(person)
    
    result = MailingList.get_emails_for_email_list("xxx")
    
    # clean up
    coll.remove(person)
    
    result.should == "test@lawrenceultimate.com"
    MailingList.get_emails_for_email_list("xxx").should == ""
  end
  it "should return one email address for a list with one person in it" do
    db = get_db
    coll = db.collection("people")
    
    person = {"full_name_and_email" => "test@lawrenceultimate.com", "email-list" => "xxx"}
    coll.save(person)
    
    result = MailingList.get_emails_for_email_list("xxx")
    
    # clean up
    coll.remove(person)
    
    result.should == "test@lawrenceultimate.com"
  end
  it "should return two email address for a list with two people in it" do
    db = get_db
    coll = db.collection("people")
    
    person1 = {"full_name_and_email" => "test@lawrenceultimate.com", "email-list" => "xxx"}
    coll.save(person1)
    
    person2 = {"full_name_and_email" => "test2@lawrenceultimate.com", "email-list" => "xxx"}
    coll.save(person2)
    
    result = MailingList.get_emails_for_email_list("xxx")
    
    # clean up
    coll.remove(person1)
    coll.remove(person2)
    
    result.should == "test@lawrenceultimate.com,test2@lawrenceultimate.com"
  end  
end