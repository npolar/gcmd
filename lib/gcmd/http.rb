require "faraday"
require "faraday_middleware"
require "rack/cache"

module Gcmd
  class Http

    BASE = "https://gcmdservices.gsfc.nasa.gov"

    OPTS = {
    }
    attr_accessor :log
    attr_reader :response
    attr_writer :username, :password

    def initialize(base=BASE, opts={}, &builder)
      @base = base
      @opts = OPTS.merge(opts)
      @client = connection(&builder)
      @log = ENV["GCMD_ENV"] == "test" ? Logger.new("/dev/null") : Logger.new(STDERR)
    end

    def base
      @base
    end

    # The Faraday connection object
    def connection(&builder)
      @client ||= begin
        f = Faraday.new(base, opts)
        f.build do |b|
          builder.call(b)
        end if builder
        f
      end
    end
  
    def get(uri)      
      
      if username.nil? or username.empty? or password.nil? or password.empty?
        raise Exception, "Please provide username/password for #{uri}"
      end

      log.debug("GET #{uri} [#{self.class.name}#get] #{username}:#{password.gsub(/./, "*")}")

      @client.basic_auth username, password

      @response = @client.get(uri)
      log.debug [@response.status, @response.headers]

      unless [200, 304].include? response.status
        raise Exception, "GET #{connection.url_prefix}#{uri} failed with status: #{response.status}"
      end
      @response.body
    end
    
     def head(uri)      
      @client.basic_auth username, password
      @response = @client.head(uri)
    end
    
    def host
      @client.host
    end

    def opts
      @opts
    end

    #def cache_dir
    #  File.join(ENV['TMPDIR'] || "/tmp", host)
    #end

    def username
      # export GCMD_HTTP_USERNAME=http_username
      @username ||= ENV["GCMD_HTTP_USERNAME"]
    end

    def password
      # export GCMD_HTTP_PASSWORD=http_password
      @password ||= ENV["GCMD_HTTP_PASSWORD"]
    end

  end
end