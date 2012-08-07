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
    
    # Default DIF schema (DIF version 9.8.3)
    XSD = "lib/gcmd/dif.xsd"
    
    def initialize( xml_schema = XSD )
      self.schema=xml_schema
    end
    
    def schema
      @schema
    end
    
    def schema=xml_schema
      @schema = load_xml( xml_schema )
    end
    
    # Generate an information Hash from the XML schema. This is
    # basically a translation from XML schema to a Hash schema.
    # @see #generate_info
    
    def info
      generate_info( root )
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
    
    def unbounded      
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
    
    protected
    
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