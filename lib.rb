def get_emails_object_for_team(team)
  db = get_db 
	coll = db.collection('people')
	people = coll.find({"team" => team})
	
	email = Array.new
	people.each do |person|
	  email.push person
	end
	
	email
end

class MailingListTranslator
  def self.get_inbox_from_email_address(email_address)
    inbox = email_address.gsub(/@.+/, "").gsub(/[^<]+</, "")
    inbox
  end
end

class MailingList
  def self.get_emails_for_email_list(list)
    db = get_db
    coll = db.collection('people')
    @people = coll.find({"email-list" => list})
    
    email = Array.new
    @people.each do |person|
      email.push person["full_name_and_email"]
    end
    
    email.join(",")
  end
end

def get_emails_for_recipient(to) 
  list = MailingListTranslator.get_inbox_from_email_address(to)
  to_email = MailingList.get_emails_for_email_list(list)
  to_email
end

def send_email(options)
  Mail.defaults do 
    delivery_method :smtp, 
    { 
    :address   => "smtp.sendgrid.net",
    :port      => 587,
    :domain => "lawrenceultimate.com",
    :user_name => "app2357454@heroku.com",
    :password  => "9dtx7amf",
    :authentication => 'plain',
    :enable_starttls_auto => true }
  end
  
  if(settings.environment == :development)
    options['html'] = "Email would have gone to: [#{options['to'].encode_for_html}] and bcc'd [#{options['bcc'].encode_for_html}] -- \n<br /><br />  #{options['html']}"
    options['to'] = "calebcauthon+devlist@gmail.com"
    options['bcc'] = ""
    options['subject'] = "dev: #{options['subject']}"
  end
  
  mail = Mail.deliver do
    to options['to']
    bcc options['bcc']
    from options['from']
    reply_to options['reply_to']
    subject options['subject']
    text_part do
      body options['text']
    end
    html_part do
      content_type 'text/html; charset=UTF-8'
      body options['html']
    end
  end
end