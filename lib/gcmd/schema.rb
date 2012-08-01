require "gcmd/tools"
require "nokogiri"

module Gcmd

  # Class aimed at XML schema manipulation. Although this class
  # was designed to be used with DIF it's made as general as
  # possible. As a result it should be fairly easy to adapt the
  # code to work for other XML schemas as well.
  #
  # [Functionality]
  #   * Hash template generation from XML schema files
  #   * Information collection
  #
  # @see http://nokogiri.org/ Nokogiri XML/HTML parsing library
  #
  # @author Ruben Dens
  # @author Conrad Helgeland

  class Schema < Gcmd::Tools
    
    def initialize( xml_schema )
      self.schema=xml_schema
    end
    
    def schema
      @schema
    end
    
    def schema=xml_schema
      @schema = load_xml( xml_schema )
    end
    
    # Generate an information Hash from the XML schema. This is basically a translation from
    # XML schema to a Hash schema. It's recommended to use the resulting output from this
    # for further operations since Xpath operations and XML operations are generally more
    # expensive then hashs operations.
    
    def collect_info

    end
    
    # This is a recursive method that walks the XML structure. It makes sure that data
    # is collected from all lvls of the schema. It returns a Hash object
    
    def generate_info

    end
    
    # Generate Template from XML xml_schema
    # This returns a Ruby Hash object of the
    # document described in the xml_schema
    
    def hash_template

    end
    
    protected
    
    def children?( name )
      return true if schema.xpath("//xs:element[@name='#{name}']/xs:complexType").any?
      false
    end
    
    def child?( name )
      return true if schema.xpath("//@ref='#{name}'")
      false
    end
    
    def unbounded?( element )
      return true if element.xpath("//@maxOccurs").to_s == "unbounded"
      false
    end
    
    def required?( element )
      return true if element.xpath("//@minOccurs").to_s == "1"
      false
    end
    
    def root?( name )
      return true unless child?( name )
      false
    end
    
    def root
      # Checks all elements and if they occur as a ref.
      # If not a ref they are root elements.
      
      schema.xpath("//xs:element[@name]").each do | element |
        name = element.xpath("./@name").to_s
        return name unless child?( name )
      end
    end
  
  end

end