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
  # @see http://gcmd.gsfc.nasa.gov/User/difguide/difman.html DIF Guide
  # @see http://gcmd.nasa.gov/Aboutus/xml/dif/dif.xsd DIF XML Schema
  # @see http://gcmd.nasa.gov/Aboutus/ About GCDM
  #
  # @author Ruben Dens
  # @author Conrad Helgeland
  
  class DifBuilder < Gcmd::Tools
    
    REQUIRED = ["Data_Center", "Entry_ID", "Entry_Title", "ISO_Topic_Category",
                "Metadata_Name", "Metadata_Version", "Parameters", "Summary"]
    
    NAMESPACE = "http://gcmd.gsfc.nasa.gov/Aboutus/xml/dif/"
    
    VERSION = "9.8.3"
    
    attr_accessor :schema, :hash_template
    
    def initialize
      self.schema = Gcmd::Schema.new
      self.hash_template = schema.hash_template
    end
    
    # This is a convenience method used to call sync_with_template on
    # the data before creating the xml structure
    # @see #build_xml
    # @see #sync_with_template
    
    def build_dif( dif_hash = nil )
      unless dif_hash.nil?
        dif_hash = sync_with_template( dif_hash, hash_template )        
        build_xml( dif_hash )
      else
        raise ArgumentError, "No data provided" 
      end    
    end
    
    # @todo Extract root node declaration and make completely generic
    #
    # This method builds an XML String from Hash data using
    # the Nokogiri::XML::Builder class.
    # @see #build_from_hash
      
    def build_xml( data_hash = nil )      
      unless data_hash.nil?
        
        builder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do | xml |
          
          xml.DIF(:xmlns => NAMESPACE,
            "xsi:schemaLocation" => "#{NAMESPACE} #{NAMESPACE}dif_v#{VERSION}.xsd",
            "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance") {          

            build_from_hash( xml, data_hash )          
          }
          
        end        
      else
        raise ArgumentError, "No Hash data provided!"
      end
      
      builder.to_xml      
    end
    
    # A recursive function that loops the Hash and detects nested
    # Hashes and Arrays. On a nested Hash a recursive call happens
    # on an Array build_from_array is called.
    # @see #build_from_array
    
    def build_from_hash( xml_builder, hash )
      
      hash.each do | key, value |
        
        if value.is_a? String
          xml_builder.send( key, value )
        elsif value.is_a? Hash
          xml_builder.send( key ) { build_from_hash( xml_builder, value ) }
        elsif value.is_a? Array
          build_from_array( xml_builder, key, value )
        end
        
      end
      
      xml_builder
    end
    
    # If the Hash contains Arrays they are read here. When
    # the array contains string values it generates XML elements
    # for each value. If it contains Hashses it calls build_from_hash
    # @see #build_from_hash
    
    def build_from_array( xml_builder, key, array )
      
      if array.any?
        array.each do | item |
          if item.is_a? Hash
            xml_builder.send(key) { build_from_hash( xml_builder, item ) }
          elsif item.is_a? String
            xml_builder.send(key, item)
          end
        end
      else
        xml_builder.send(key, "")
      end
      
      xml_builder
    end
    
    # @note This feature requires Ruby 1.9 or above since it
    #   requires ordered hashes.
    #
    # Sorts a provided hash based on the assosiated template and merges
    # it with the provided template. This function is recursive.
    # @see #sync_array
    
    def sync_with_template( hash, template = nil )
      completed = {}
     
      unless template.nil?
        
        template.each do | key, value |
          unless hash[key].nil?          
            if hash[key].is_a? String
              completed[key] = hash[key]
            elsif hash[key].is_a? Hash
              completed[key] = sync_with_template( hash[key], value )
            elsif hash[key].is_a? Array
              completed[key] = sync_array( hash[key], value.first )
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
    #   makes use of ordered hashes.
    #    
    # Sorts an array based on the provided template.
    # @see #sync_with_template
    
    def sync_array( array, template=nil )
      
      data = []
      
      if array.any?        
        array.each do | item |
          if item.is_a? String
            data << item
          elsif item.is_a? Hash
            data << sync_with_template( item, template )
          end
        end
      else
        data << template        
      end
      
      data
    end
    
    # Calls build XML with a template Hash build from the schema
    # @see Gcdm::Schema
    
    def xml_template
      build_xml( hash_template )
    end
    
  end  
end
