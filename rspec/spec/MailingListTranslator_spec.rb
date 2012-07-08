require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "MailingListTranslator" do
  mlt = MailingListTranslator
  it "should exist" do
    MailingListTranslator
  end
  it "should have a method to grab /caleb/ from /caleb@lawrenceultimate.com/" do
    result = mlt.get_inbox_from_email_address "caleb@lawrenceultimate.com"
    result.should == "caleb"
  end
  it "should have a method to grab /caleb/ from /caleb <caleb@lawrenceultimate.com>/" do
    result = mlt.get_inbox_from_email_address "caleb <caleb@lawrenceultimate.com>"
    result.should == "caleb"
  end
end