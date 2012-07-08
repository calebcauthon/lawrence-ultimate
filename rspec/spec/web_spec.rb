
require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Sinatra App" do
  it "should respond to GET" do
    get '/'
    last_response.should be_ok
  end
end

describe "Mailing List" do
  it "should be using the dev database" do
    settings.db_name.should == "lusl-dev"
  end
  
  it "should return the right list of emails" do
    
  end
end