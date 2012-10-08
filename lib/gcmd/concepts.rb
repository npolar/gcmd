require "nokogiri"
require "fileutils"
require "digest/sha1"
require "logger"

module Gcmd
  class Concepts

    # http://gcmdservices.gsfc.nasa.gov/kms/concept_versions/all
    VERSION = "Jun122012"

    CACHE = ENV["GCMD_CONCEPTS_CACHE"] ||= File.join(File.dirname(__FILE__)+"/_concepts")

    BASE = Http::BASE + "/kms/concepts/"

    NAMESPACE = {
      "gcmd" => "http://gcmd.gsfc.nasa.gov/",
      "rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
      "skos" => "http://www.w3.org/2004/02/skos/core#"
    }

    ROOT_SCHEMAS = ["chronounits", "sciencekeywords", "locations", "providers",
      "platforms", "instruments", "projects", "discipline", "idnnode",
      "isotopiccategory", "rucontenttype", "horizontalresolutionrange",
      "verticalresolutionrange", "temporalresolutionrange"].sort

    attr_accessor :base, :cache, :http, :log

    def self.schemas
      ROOT_SCHEMAS
    end

    def self.valid?(xml)
      if xml =~ /http\:\/\/www.w3.org\/2004\/02\/skos\/core#/
        begin
          Nokogiri::XML(xml).xpath("//skos:Concept").size >= 1
        rescue => e
          false
        end
      else
        false
      end

    end
    
    def initialize
      @base = BASE
      @cache = CACHE
      @http = Http.new(base)
      @log = ENV["GCMD_ENV"] =="test" ? Logger.new("/dev/null") : Logger.new(STDERR)
      
      unless false == cache
        add_concepts_from_cache
      end
    end

    def addConcept(scheme, xml)
      unless @concept.is_a? Hash
        @concept = {}
      end
      if File.exists? xml
        f = File.open(xml)
        f.set_encoding("UTF-8")
        xml = f.read
      end
      unless self.class.valid? xml
        raise Exception, "Added #{scheme} XML does not contain a skos:Concept"
      end
      @concept[scheme] = xml
    end

    def add_concepts_from_cache
      (["root"]+self.class.schemas).each do |scheme|
        filename = File.join(cache, version, scheme)
          if File.exists? filename
            addConcept(scheme, filename)
          end
      end
    end

    def concept(scheme)
      unless concept? scheme
        fetch(scheme)
      end
      @concept[scheme]
    end

    def concept?(scheme)
      @concept.respond_to? :key? and @concept.key? scheme
    end

    def filter(scheme, q, range = 0..99)
      q = q.gsub(/\W/, "")
      regexp = /#{q}/ui
      tuples(scheme).select {|c| c[1] =~ regexp }[range]
    end

    def get(uri)
      http.get(uri)
    end

    def isotopiccategory
      narrower("isotopiccategory")
    end

    def idnnode
      narrower("idnnode")
    end

    def projects
      narrower("projects")
    end

    def sciencekeywords
      narrower("sciencekeywords")
    end

    def providers
      narrower("providers")
    end

    def narrower(scheme="root")
      ng = Nokogiri::XML concept(scheme)
      if "root" == scheme
        r = ng.xpath("//skos:Concept", NAMESPACE)
      else
        r = ng.xpath("//skos:Concept[skos:broader]", NAMESPACE)
      end
      r = r.map {|r| [r.xpath("@rdf:about").to_s , r.xpath("./skos:prefLabel[@xml:lang='en']").text, r.xpath("./skos:definition[@xml:lang='en']").text  ]}
      r.select {|r| r[1] != "Trash Can" }
    end
    alias :triples :narrower


    def tuples(scheme)
      narrower(scheme).map {|c| [c[0], c[1]]}
    end

    def names(scheme="root")
      narrower(scheme).map {|c|c[1]}
    end

    def root
      narrower("root").sort
    end

    def fetch_all

      log.debug "Fetching all GCMD Concepts (RDF XML) to #{cache}"

      f = []
      version = VERSION
      (["root"]+schemas).each do | scheme |
        log.debug "#{self.class.name}#fetch_all [#{scheme}]"
        f << fetch(scheme)
      end
      log.debug "Finished #fetch_all"
      f
    end

    def fetch(scheme, uri=nil)

      base = scheme != "root" ? BASE+"concept_scheme/" : BASE

      if uri.nil?
        uri = base+scheme+"?format=rdf"
      end
      log.debug "#{self.class.name}#fetch #{uri}"
      
      xml = get(uri)

      if self.class.valid? xml

        # The source does not provide ETag or Last-Modified :/
        
        addConcept(scheme, xml)
  
        version = keywordVersion(scheme) 
  
        filename = File.join(cache, version, scheme)
        
        status = save(filename, xml)
        
      else
        log.error("Invalid #{scheme} XML from #{uri}:\n#{xml}")
        raise Gcmd::Exception, "Refuse to save invalid concept #{scheme} (version:#{version})"
      end
      status

    end

    def save(filename, data)
      dir = File.dirname(filename)
      unless File.exists? dir
        FileUtils.mkpath dir
      end
      
      if File.exists? filename
        existing_sha1 = Digest::SHA1.hexdigest File.read(filename)
        log.debug "Existing SHA-1: #{existing_sha1}"
      end

      new_sha1 = Digest::SHA1.hexdigest data

      if false == File.exists?(filename) or existing_sha1 != new_sha1
        f = File.open(filename, "w")
        size = f.write(data)
        f.close 
        log.debug "Saved: #{filename}"
        ret = (size > 0) ? true : false
        
      else
        log.debug "No change/not saved: #{filename}"
        ret = true
      end
      ret
      
    end

    def schemas
      self.class.schemas
    end

    def keywordVersion(scheme="root")
      ng = Nokogiri::XML concept(scheme)
      r = ng.xpath("//gcmd:keywordVersion", {"gcmd" => "http://gcmd.gsfc.nasa.gov/"}).first.text
    end

    def version
      @version ||= VERSION
    end
  
  end

end
