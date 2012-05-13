# gem install httparty
# ruby wufoo.rb

require 'rubygems'
require 'httparty'
require 'forwardable'

module Wufoo
  API_VERSION = 3
  BASE_URL = "https://%s.wufoo.com/api/v%s/%s?pageSize=100"
  
  class <<self        
    def login(subdomain, api_key)
      Session.new(subdomain, api_key)
    end
  end
  
  class Session
    attr_accessor :subdomain, :api_key
    
    def initialize(subdomain, api_key)
      @subdomain = subdomain
      @api_key = api_key
    end
    
    def credentials
      {:username => @api_key, :password => "n3rdZr00l"}
    end
    
    def base_url
      Wufoo::BASE_URL.dup % [@subdomain, Wufoo::API_VERSION, "%s"]
    end
    
    def users
      ResourceCollection.new(User, self)
    end
    
    def forms
      ResourceCollection.new(Form, self)
    end
    
    def reports
      ResourceCollection.new(Report , self)
    end
  end
  
  class ResourceCollection
    extend Forwardable
    
    attr_accessor :resource_class, :parent_path
    
    def initialize(klass, session, parent_path=nil)
      @resource_class = klass
      @parent_path = parent_path
      @session = session
    end
    
    def to_a
      @array ||= reload
    end
    
    def reload
      @array = @resource_class.get_all(@session, @parent_path)
    end
    
    alias_method :all, :to_a
    
    def find(id)
      @resource_class.get(@session, id, @parent_path)
    end
    
    def_delegators :to_a, :clear, :first, :push, :shift, :size, :length, :each, :map, :select, :collect
  end
  
  class PostableCollection < ResourceCollection
    def create(attrs)
      url = @session.base_url % @resource_class.collection_path(@parent_path)
      
      response = post_resource(url, attrs)
      
      if response['Success'].to_s == "1"
        reload
        response['EntryID']
      else
        false
      end
    end
    
    def create!(attrs)
      raise "Save failed!" unless create(attrs)
    end
    
    alias_method :submit, :create
    alias_method :submit!, :create!

    def post_resource(url, attrs)
      HTTParty.post(url, :body => attrs, :basic_auth => @session.credentials)
    end
  end  
    
  class Resource
    class <<self
      def resource_collection_name(value)
        @collection_path = value
      end
      
      def base_name
        @base_name ||= name.gsub(/(.*)\:\:/, '').downcase
      end
      
      def collection_path(parent_path="%s")
        (parent_path || "%s") % (@collection_path ? "#{@collection_path}.json" : "#{base_name}s.json")
      end
      
      def resource_path(id, parent_path="%s")
        (parent_path || "%s") % (@collection_path ? "#{@collection_path}/#{id}" : "#{base_name}s/#{id}.json")
      end
    
      def get_all(session, parent_path=nil)
        url = session.base_url % collection_path(parent_path)

        HTTParty.get(url, :basic_auth => session.credentials).first.last.map {|values| from_params(values, session) }
      end
    
      def get(session, identifier, parent_path=nil)   
        url = session.base_url % resource_path(identifier, parent_path)
        
        from_params(HTTParty.get(url, :basic_auth => session.credentials), session)
      end
    
      def from_params(params, session)
        new_object = new
        new_object.attrs = params
        new_object.session = session
        
        new_object
      end
    end

    attr_accessor :attrs, :session

    def initialize(attrs={})
      @attrs = attrs
    end

    def method_missing(m, *args)
      camel_cased = m.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
      @attrs[m.to_s] or @attrs[camel_cased] or super
    end
  end
  
  class User < Resource
    def avatar_url(size="big")
      session.base_url % "images/avatars/#{size}/#{self.image}"
    end
  end
  
  class Form < Resource
    def parental_path
      "forms/#{self.hash}/%s"
    end
    
    def fields
      ResourceCollection.new(Field, session, parental_path)
    end
    
    def entries
      PostableCollection.new(Entry, session, parental_path)
    end
    
    def comments
      ResourceCollection.new(Comment, session, parental_path)
    end
    
    def hash
      @attrs['Hash']
    end
  end
  
  class Report < Resource
    def parental_path
      "reports/#{self.hash}/%s"
    end
    
    def fields
      ResourceCollection.new(Field, session, parental_path)
    end
    
    def widgets
      ResourceCollection.new(Widget, session, parental_path)
    end
    
    def entries
      PostableCollection.new(Entry, session, parental_path)
    end      
    
    def hash
      @attrs['Hash']
    end
  end
  
  # Owned by forms and reports
  class Entry < Resource
    resource_collection_name "entries"
  end
  
  # Owned by forms and reports
  class Field < Resource
  end
  
  # Owned by reports
  class Widget < Resource
  end
  
  # Owned by forms
  class Comment < Resource
  end

  # Owned by forms
  class WebHook < Resource
  end
end
