require "nokogiri"

module Gcmd

  # Class aimed at XML schema manipulation. Although this class
  # was designed to be used with DIF it's made as general as
  # possible. As a result it should be fairly easy to adapt the
  # code to work for other XML schemas as well.
  #
  # [Functionality]
  #   * Hash template generation from XML schema files
  #   * Information collection:
  #     - Gather occurence information
  #     - Gather required fields
  #
  # [License]
  #   This code is licensed under the {http://www.gnu.org/licenses/gpl.html GNU General Public License Version 3} (GPLv3)
  #
  # @see http://nokogiri.org/ Nokogiri XML/HTML parsing library
  #
  # @author Ruben Dens
  # @author Conrad Helgeland

  class Schema < Gcmd::Tools
    
    NAMESPACE = { "dif" => "http://gcmd.gsfc.nasa.gov/Aboutus/xml/dif/" }
    
    XPATH = "//dif:DIF"
    
    VERSION = "9.8.3"
    
    # Default DIF XML schema, by default in ~/.gcmd/dif/dif.xsd
    XSD = Gcmd::CACHE + "/dif/dif.xsd"
    attr_accessor :info, :unbounded, :location
    
    def initialize( xml_schema = XSD )
      self.location = xml_schema
      self.schema = xml_schema
      self.info = generate_info( root )
      self.unbounded = generate_unbounded
    end
    
    def schema
      @schema
    end
    
    def schema=xml_schema
      @schema = load_xml( xml_schema )
    end
    
    # This is a recursive method that walks the XML structure.
    # It makes sure that data is collected from all levels of
    # the schema.
    
    def generate_info( node )
      information = {}
      
      schema.xpath("//xs:element[@name='#{node}']/xs:complexType/xs:sequence/xs:element").each do | child |
        name = child.xpath("./@ref").to_s        
        children = generate_info( name ) if has_children?( name )
        
        information[name] = {
          "required" => required?( child ),
          "unbounded" => unbounded?( child )
        }
        
        information[name]["children"] = children unless children.nil?
      end
      
      information
    end
    
    # Generate a Hash template from the #info
    
    def hash_template
      template = {}
      
      info.each do | key, value |
        template[key] = generate_structure( value )
      end
      
      template
    end
    
    # Recursive function that checks the information
    # Hash for every element and generates the proper
    # value structure.
    
    def generate_structure( value )
      part = {}
      unless value.has_key?( "children" )
        return [] if value["unbounded"]
        return ""
      else
        value["children"].each do | key, value |
          part[key] = generate_structure(value)
        end       
      end
      
      return [part] if value["unbounded"]
      part 
    end
    
    # Returns an array with unbounded elements
    
    def generate_unbounded
      elements = []

      info.each do | key, value |
        elements << key if value["unbounded"]
        elements << lookup_unbounded( value )        
      end
      
      elements.flatten
    end
    
    # Recursively look up unbounded child elements
    
    def lookup_unbounded( value )
      elements = []
      if value.has_key?( "children" )
        value["children"].each do |key, value|
          elements << key if value["unbounded"]
          if value.has_key?( "children" )
            elements << lookup_unbounded( value )
          end
        end
      end
      elements
    end    
    
    def validate_xml( xml = nil )
      errors = []
      
      raise ArgumentError, "No XML provided!" if xml.nil?
      xml = Nokogiri::XML::Document.parse( xml ) unless xml.is_a?( Nokogiri::XML::Document )
      
      xml.xpath( XPATH, NAMESPACE ).each_with_index do | node, index |
        errs = nokogiri_schema.validate( Nokogiri::XML::Document.parse( node.to_s ) )
        
        errors << {
          "Entry_Title" => node.xpath(".//dif:Entry_Title", NAMESPACE).first.text,
          "Entry_ID" => node.xpath(".//dif:Entry_ID", NAMESPACE).first.text,
          "details" => errs
        } if errs.any?
        
      end
      
      errors
    end
    
    def schema_location
      "#{NAMESPACE['dif']}dif_v#{VERSION}.xsd"
    end
    
    protected
    
    def nokogiri_schema
      Nokogiri::XML::Schema( File.read( location ) )
    end
    
    def has_children?( name )
      return true if schema.xpath("//xs:element[@name='#{name}']/xs:complexType/xs:sequence").any?
      false
    end
    
    def child?( name )
      return true if schema.xpath("//@ref='#{name}'")
      false
    end
    
    def unbounded?( element )
      return true if element.xpath("./@maxOccurs").to_s == "unbounded"
      false
    end
    
    def required?( element )
      return true if element.xpath("./@minOccurs").to_s == "1"
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