class String
  def encode_for_email
    self.force_encoding('ISO-8859-1').encode!('UTF-8',invalid: :replace,undef: :replace,replace: '?')
  end
  
  def encode_for_html
    self.gsub!(/</, '&lt;')
    self.gsub!(/>/, '&gt;')
  end
end