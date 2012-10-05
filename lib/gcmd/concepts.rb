require "nokogiri"
require "fileutils"
require "digest/sha1"
require "logger"

module Gcmd
  class Concepts

    # http://gcmdservices.gsfc.nasa.gov/kms/concept_versions/all
    VERSION = "Jun122012"

    CACHE = File.join(File.dirname(__FILE__)+"/_concepts")

    BASE = Http::BASE + "/kms/concepts/"

    NAMESPACE = {
      "gcmd" => "http://gcmd.gsfc.nasa.gov/",
      "rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
      "skos" => "http://www.w3.org/2004/02/skos/core#"
    }

    ROOT_SCHEMES = ["chronounits", "sciencekeywords", "locations", "providers",
      "platforms", "instruments", "projects", "discipline", "idnnode",
      "isotopiccategory", "rucontenttype", "horizontalresolutionrange",
      "verticalresolutionrange", "temporalresolutionrange"].sort

    attr_accessor :base, :cache, :http, :log

    def self.schemas
      ROOT_SCHEMES
    end
    
    def initialize(base=BASE, cache=CACHE)
      @base = base
      @cache = cache
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
        xml = File.open(xml).read
      end
      unless self.class.valid? xml
        raise Exception, "Added #{scheme} XML does not contain a skos:Concept"
      end
      @concept[scheme] = xml
    end

    def add_concepts_from_cache
      (["root"]+ROOT_SCHEMES).each do |scheme|
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
      narrower(scheme).select {|c| c[1] =~ regexp }[range]
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

    def narrower_names(scheme="root")
      narrower(scheme).map {|c|c[1]}
    end

    def root
      narrower("root").sort
    end

    def fetch_all
      f = []
      version = VERSION
      (["root"]+schemes).each do | scheme |
        log.debug "About to fetch: #{scheme}"
        f << fetch(scheme)
      end
      f
    end

    def fetch(scheme, uri=nil)
      base = scheme != "root" ? BASE+"concept_scheme/" : BASE
      if uri.nil?
        uri = base+scheme+"?format=rdf"
      end
      log.debug uri
      xml = get(uri)

      # Once the source provide a datestamp, we should set the file date to that
      addConcept(scheme, xml)
      version = keywordVersion(scheme)
      filename = File.join(cache, version, scheme)
      
      sha1 = Digest::SHA1.hexdigest xml

      if self.class.valid? xml
        save(filename, xml, sha1)
      else
        log.error("Invalid #{scheme} XML from #{uri}:\n#{xml}")
        raise Gcmd::Exception, "Refuse to save invalid concept #{scheme} (version:#{version})"
      end

      sha1
    end

    def save(filename, data, sha1=nil)
      dir = File.dirname(filename)
      unless File.exists? dir
        FileUtils.mkpath dir
      end
      
      if File.exists? filename
        existing_sha1 = Digest::SHA1.hexdigest File.read(filename)
        log.debug "Existing SHA-1: #{existing_sha1}"
      end

      if existing_sha1.nil? or existing_sha1 != sha1

        # if self.valid? data

        f = File.open(filename, "w")
        f.write(data)
        f.close
        log.debug "Saved: #{filename}"
      else
        log.debug "No change: #{filename}" 
      end
    end

    def schemes(scheme="root")
      if "root" == scheme and false == concept?("root")
        return ROOT_SCHEMES
      end
      unless concept? scheme
        raise Exception, "Concept #{scheme} is missing"
      end
      ng = Nokogiri::XML concept(scheme)
      schemes = ng.xpath("//skos:Concept/skos:inScheme/@rdf:resource", NAMESPACE).map {|r| r.to_s.split("/concept_scheme/").last }.sort
      schemes.select {|s| s != "Trash" }
    end

    def keywordVersion(scheme="root")
      ng = Nokogiri::XML concept(scheme)
      r = ng.xpath("//gcmd:keywordVersion", {"gcmd" => "http://gcmd.gsfc.nasa.gov/"}).first.text
    end

    def version
      @version ||= VERSION
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
  
  end

end
