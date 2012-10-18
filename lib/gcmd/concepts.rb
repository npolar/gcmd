require "nokogiri"
require "fileutils"
require "digest/sha1"
require "logger"

module Gcmd
  class Concepts
    # http://gcmdservices.gsfc.nasa.gov/kms/concept_versions/all
    #<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    #<versions xsi:noNamespaceSchemaLocation="http://gcmd.nasa.gov/kms/gcmd.xsd">
    #    <version id="3" creation_date="2012-10-09" type="PUBLISHED">7.0</version>
    #    <version id="5" creation_date="2012-10-09" type="DRAFT">draft</version>
    #    <version id="1" creation_date="2012-06-12" type="PAST_PUBLISHED">Jun122012</version>
    #</versions>
    VERSION = "7.0"

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

    def self.schemas(root=false)
      if root or "root" == root
        ["root"] + ROOT_SCHEMAS
      else
        ROOT_SCHEMAS
      end
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
    
    def initialize(version=VERSION)
      @base = BASE
      @cache = CACHE
      @http = Http.new(base)
      @log = ENV["GCMD_ENV"] =="test" ? Logger.new("/dev/null") : Logger.new(STDERR)
      @version = version
      unless false == cache
        add_concepts_from_cache
      end
      @ng_concept_cache = {}
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

    def collection(schema)

      collection = ng(schema).xpath("//skos:Concept").map {|concept|
        
        id = concept.xpath("@rdf:about").text

        @ng_concept_cache[id] = concept

        summary = concept.xpath("skos:definition[@xml:lang='en']").text
        title = concept.xpath("skos:prefLabel[@xml:lang='en']").text
        broader_id = concept.xpath("skos:broader/@rdf:resource").text
        broader_id = broader_id == "" ? nil : broader_id        
        narrower_ids = concept.xpath("skos:narrower/@rdf:resource").map {|n| n.to_s }
        changeNote = concept.xpath("skos:changeNote").text

        if broader_id.nil?
          tree = :root
        elsif narrower_ids.any?
          tree = :branch
        else
          tree = :leaf
        end
        {
          :id => id,
          :label => title,
          :title => title,
          :summary => summary,
          :broader_id => broader_id,
          :narrower_ids => narrower_ids,
          :changeNote => changeNote,
          :collection => schema,
          :workspace => :gcmd,
          :version => version,
          :lang => :en,
          :tree => tree
        }
      }.map do | c |
        
        c[:narrower] = c[:narrower_ids].map {|id|
          @ng_concept_cache[id].xpath("skos:prefLabel[@xml:lang='en']").text
        }
        if c[:broader_id].nil?
          c[:ancestors] = []
        else
          c[:broader] = @ng_concept_cache[c[:broader_id]].xpath("skos:prefLabel[@xml:lang='en']").text

          ancestors = recursive_ancestors(schema, c[:broader_id])

          c[:ancestors] = [c[:broader]] + ancestors[:ancestors]
          c[:ancestor_ids] = [c[:broader_id]] + ancestors[:ids]

          c[:title] = c[:title] +" ("+ c[:ancestors].reverse.join(" > ") +")"
        end
        c.delete :broader
        c.delete :broader_id
        c
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
      if "root" == scheme
        r = ng(scheme).xpath("//skos:Concept", NAMESPACE)
      else
        r = ng(scheme).xpath("//skos:Concept[skos:broader]", NAMESPACE)
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

    def ng(schema)
      Nokogiri::XML concept(schema)
    end
    alias :nokogiri :ng

    def schemas(root=false)
      self.class.schemas(root)
    end

    def keywordVersion(scheme="root")
      r = ng(scheme).xpath("//gcmd:keywordVersion", {"gcmd" => "http://gcmd.gsfc.nasa.gov/"}).first.text
    end

    def version
      @version ||= VERSION
    end

    protected

    def recursive_ancestors(schema, broader_id, ancestors = [], ids = [])
      parent = @ng_concept_cache[broader_id].xpath("skos:broader/@rdf:resource").text      
      if parent.size > 0
        ids << parent
        ancestors << @ng_concept_cache[parent].xpath("skos:prefLabel[@xml:lang='en']").text
        recursive_ancestors(schema, parent, ancestors, ids)
      else
        { :ids => ids, :ancestors => ancestors }
      end
    end
  
  end

end
