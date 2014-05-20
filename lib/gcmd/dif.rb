require "nokogiri"
require "hashie"
require "nori"
module Gcmd
  
  # DIF document
  # * Read, manipulate, and write DIF XML documents
  #
  # [License]
  # {http://www.gnu.org/licenses/gpl.html GNU General Public License}
  #
  # @see http://gcmd.gsfc.nasa.gov/User/difguide/difman.html DIF Guide
  # @see http://gcmd.nasa.gov/Aboutus/xml/dif/dif.xsd DIF XML Schema
  # @see http://gcmd.nasa.gov/Aboutus/ About GCDM
  #
  # @author Ruben Dens
  # @author Conrad Helgeland
  
  class Dif < ::Hashie::Mash
    
    NAMESPACE = { "dif" => "http://gcmd.gsfc.nasa.gov/Aboutus/xml/dif/", "xs" => "http://www.w3.org/2001/XMLSchema" }
    
    DIF_XPATH = "//dif:DIF" 
    
    EXCLUDED = ["Fax", "Phone"]
    
    KEYS = ["Entry_ID","Entry_Title","Data_Set_Citation","Personnel","Discipline","Parameters","ISO_Topic_Catsegory","Keyword","Sensor_Name","Source_Name","Temporal_Coverage","Paleo_Temporal_Coverage","Data_Set_Progress","Spatial_Coverage","Location","Data_Resolution","Project","Quality","Access_Constraints","Use_Constraints","Data_Set_Language","Originating_Center","Data_Center","Distribution","Multimedia_Sample","Reference","Summary","Related_URL","Parent_DIF","IDN_Node","Originating_Metadata_Node","Metadata_Name","Metadata_Version","DIF_Creation_Date","Last_DIF_Revision_Date","DIF_Revision_History","Future_DIF_Review_Date","Private","Extended_Metadata"]
    
    attr_accessor :document, :schema, :excluded, :errors
    
    # FIXME Design flaw makes #initialize being called also on child properties (Hashie::Mash due to deep update)
    def initialize( document=nil, schema=Gcmd::Schema.new )

      @schema = schema
      
      keys = schema.info.keys
      keys = keys.none? ? KEYS : keys
            
      unless document.nil?
        load(document)
      end
    end
    
    # 
    # Detect documents in the XML based on xpath information and calls
    # the parser on each document. This returns an Array of Hash objects.
  
    def document_to_array( xpath = DIF_XPATH, namespace = NAMESPACE)
      a = []
      document.xpath( xpath, namespace ).each do | node |
        dif = Gcmd::Dif.new
        dif.load_xml node.to_s
        a << dif.document_to_hash
      end
      a
    end
    
    #def document_to_hash
    #  document_to_array.first
    #end

    def document_to_hash
      nori = Nori.new({advanced_typecasting: false})
      dif_hash = nori.parse(document.to_s)
      dif_hash["DIF"].reject {|k,v| k=~ /^@/}
    end
    
    
    # Loads DIF XML from source (path/filename, XML string, URI)
    # Loadings sets a Nokogiri XML Document, converts it to an Hash,
    # and injects properties from this Hash into self.
    # @param source String|Nokogiri::XML::Document (Path|XML (string) |URI)
    def load_xml(source)
      #begin
        if source.is_a? Nokogiri::XML::Document
          @document = source
        else
          #source =~ /\<DIF\>/
          if source.size < 255 and File.exists? source
            source = File.read source
          end
          @document = Nokogiri::XML::Document.parse( source, nil, nil ) #, Nokogiri::XML::ParseOptions::NOBLANKS
        end
        # Sets all properties like Entry_ID for this instance
        load_hash(document_to_hash)
        
       #rescue => e
        #puts e.backtrace
        #raise ArgumentError, "Cannot load DIF XML: " + e.message[0..255]
      #end
    end
    alias :xml= :load_xml

    # Load a DIF document, either Hash or XML
    def load(document)
      if document.respond_to?(:keys)
        load_hash(document)
      else
        load_xml(document)
      end
    end

    #
    def load_hash(hash)
      unless hash.respond_to?(:each)
        raise ArgumentError, "Cannot load dataset Hash"
      end
      shallow_update hash
      
    end

    def to_xml
      builder = Gcmd::DifBuilder.new(self)
      builder.build_dif
    end
    
    def to_s
      to_xml
    end
    
    def valid?
      @errors = schema.validate(to_xml)
      @errors.none?
    end    

    protected
    
    def excluded?(key)
      excluded = @excluded ||= EXCLUDED
      excluded.include?( key )
    end
    
    def unbounded?(key)
      unbounded = @unbounded ||= schema.unbounded
      unbounded.include?(key)
    end
    
  end
end
