require "gcmd/tools"
require "gcmd/schema"

require "nokogiri"

module Gcmd
  
  # [Functionality]
  #   * Convert DIF Hashes to DIF XML
  #   * XML template generation from XML schema
  #
  # [License]
  #   This code is licensed under the {http://www.gnu.org/licenses/gpl.html GNU General Public License Version 3} (GPLv3)
  #
  # @author Ruben Dens
  # @author Conrad Helgeland
  
  class DifBuilder < Gcmd::Tools
    
    # Default DIF schema (DIF version 9.8.3)
    XSD = "lib/gcmd/dif.xsd"
    
    NAMESPACE = "http://gcmd.gsfc.nasa.gov/Aboutus/xml/dif/"
    
    VERSION = "9.8.3"
    
    def initialize( xml_schema = XSD )
      self.schema = Gcmd::Schema.new( xml_schema )
      self.hash_template = schema.hash_template
    end
    
    def schema
      @schema
    end
    
    def schema= xml_schema
      @schema = xml_schema
    end
    
    def hash_template
      @hash_template
    end
    
    def hash_template= template
      @hash_template = template
    end
    
    # This method builds an XML String from Hash data using
    # the Nokogiri::XML::Builder class.
    # @see #build_from_hash
      
    def build_xml( dif_hash = nil )      
      unless dif_hash.nil?
        
        builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do | xml |
          
          xml.DIF(:xmlns => NAMESPACE,
            "xsi:schemaLocation" => "#{NAMESPACE} #{NAMESPACE}dif_v#{VERSION}.xsd",
            "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance") {          

            build_from_hash( xml, dif_hash )          
          }
          
        end        
      else
        raise ArgumentError, "No Hash data provided!"
      end
      
      builder.to_xml      
    end
    
    # @note This feature requires Ruby 1.9 or above since it
    #   requires ordered hashes.
    #
    # Sorts a provided hash based on the assosiated template and merges
    # it with the provided template. This function is recursive.
    #
    # @see #sort_array
    
    def sort_hash( hash, template = nil )
      completed = {}
     
      unless template.nil?
        
        template.each do | key, value |
          unless hash[key].nil?          
            if hash[key].is_a? String
              completed[key] = hash[key]
            elsif hash[key].is_a? Hash
              completed[key] = sort_hash( hash[key], value )
            elsif hash[key].is_a? Array
              completed[key] = sort_array( hash[key], value.first )
            end          
          else
            completed[key] = value          
          end
        end
        
      else        
        completed = hash        
      end
      
      completed
    end
    
    # @note This feature requires Ruby 1.9 or above since it
    #   requires ordered hashes.
    #    
    # Sorts an array based on the provided template.
    #
    # @see #sort_hash
    
    def sort_array( array, template=nil )
      
      data = []
      
      if array.any?        
        array.each do | item |
          if item.is_a? String
            data << item
          elsif item.is_a? Hash
            data << sort_hash( item, template )
          end
        end
      else
        data << template        
      end
      
      data
    end
    
    # A recursive function that loops the Hash and detects nested
    # Hashes and Arrays. On a nested Hash a recursive call happens
    # on an Array build_from_array is called.
    # @see #build_from_array
    
    def build_from_hash( xml, hash )
      
      hash.each do | key, value |
        
        if value.is_a? String
          xml.send( key, value )
        elsif value.is_a? Hash
          xml.send( key ) { build_from_hash( xml, value ) }
        elsif value.is_a? Array
          build_from_array( xml, key, value ) 
        end
        
      end
      
      xml      
    end
    
    # If the Hash contains Arrays they are read here. When
    # the array contains string values it generates XML elements
    # for each value. If it contains Hashses it calls build_from_hash
    # @see #build_from_hash
    
    def build_from_array( xml, key, array )
      
      if array.any?
        array.each do | item |
          if item.is_a? Hash
            xml.send(key) { build_from_hash( xml, item ) }
          else
            xml.send(key, item)
          end
        end
      else
        xml.send(key, "")
      end
      
      xml
    end
    
    # Calls build XML with a template Hash build from the schema
    # @see Gcdm::Schema
    
    def xml_template
      build_xml( hash_template )
    end
    
  end  
end
