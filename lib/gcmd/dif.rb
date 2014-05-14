require "nokogiri"
require "hashie"

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
    
    KEYS = ["Entry_ID","Entry_Title","Data_Set_Citation","Personnel","Discipline","Parameters","ISO_Topic_Category","Keyword","Sensor_Name","Source_Name","Temporal_Coverage","Paleo_Temporal_Coverage","Data_Set_Progress","Spatial_Coverage","Location","Data_Resolution","Project","Quality","Access_Constraints","Use_Constraints","Data_Set_Language","Originating_Center","Data_Center","Distribution","Multimedia_Sample","Reference","Summary","Related_URL","Parent_DIF","IDN_Node","Originating_Metadata_Node","Metadata_Name","Metadata_Version","DIF_Creation_Date","Last_DIF_Revision_Date","DIF_Revision_History","Future_DIF_Review_Date","Private","Extended_Metadata"]
    
    attr_accessor :document, :schema, :excluded
    
    def initialize( document=nil, schema=Gcmd::Schema.new )

      @schema = schema
      
      keys = schema.info.keys
      keys = keys.none? ? KEYS : keys
      
      # Set allowed properties from XML Schema
      #keys.each do | key |
      #  self.class.property key.to_sym
      #end
      # FIXME (Dash also children of top level properties)
      
      unless document.nil?
        load document
      end
    end
    
    # Detect documents in the XML based on xpath information and calls
    # the parser on each document. This returns an Array of Hash objects.
  
    def document_to_array( xpath = DIF_XPATH, namespace = NAMESPACE)

      a = []
        
      document.xpath( xpath, namespace ).each do | node |
        dif = Gcmd::Dif.new
        dif.load_hash hash_from_xml( node.children )
        a << dif
      end
        
      a
    end

    # *Recursive* method that turns an XML tree into a Hash
    # Unbounded elements are always represented as Arrays
    # @param nokogiri_xml_nodeset Nokogiri::XML::NodeSet
    def hash_from_xml( nokogiri_xml_nodeset )
      result = {}
      nokogiri_xml_nodeset.each do |node|
        unless excluded?( node.name )
          
          result[ node.name ] = [] if unbounded?( node.name ) && result[ node.name ].nil?

          if node.children.children.any?

            if result[ node.name ].is_a?( Array )
              # Add children, @todo except those that are whitespace
              result[ node.name ] << hash_from_xml( node.children )
            else
              result[ node.name ] = hash_from_xml( node.children )
            end
          else

            #p "[n]"+node.name
            if result[ node.name ].is_a?( Array )
              #p "(array)"+node.content
              result[ node.name ] << node.content
            else
              if node.name != "text" and node.content !~ /^\s+$/
                result[ node.name ] = node.content
              end
            end
          end

        end
      end
      
      result
    end

    def document_to_hash
      document_to_array.first
    end
    
    
    # Loads DIF XML from source (path/filename, XML string, URI)
    # Loadings sets a Nokogiri XML Document, converts it to an Hash,
    # and injects properties from this Hash into self.
    # @param source String|Nokogiri::XML::Document (Path|XML (string) |URI)
    def load_xml(source)
      begin
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
        load_hash document_to_hash
        
       rescue => e
        raise ArgumentError, "Invalid XML source: " + e.message[0..255]
      end
    end
    alias :xml= :load_xml

    # Load a DIF document, either Hash or XML
    def load(document)
      if document.respond_to?(:keys)
        load_hash document
      else
        load_xml document
      end
    end

    #
    def load_hash(hash)
      unless hash.respond_to?(:each)
        raise ArgumentError, "Invalid Hashie (needs #each)"
      end
      
      hash.each do | k,v|
        self[k]=v
      end
    end

    def to_xml
      builder = Gcmd::DifBuilder.new(self)
      builder.build_dif
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
