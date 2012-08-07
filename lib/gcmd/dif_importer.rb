require "gcmd/tools"
require "gcmd/schema"

require "nokogiri"

module Gcmd
  
  # [Functionality]
  #   * Convert DIF XML to DIF Hashes
  #
  # [License]
  #   This code is licensed under the {http://www.gnu.org/licenses/gpl.html GNU General Public License Version 3} (GPLv3)
  #
  # @author Ruben Dens
  # @author Conrad Helgeland
  
  class DifImporter < Gcmd::Tools
    
    NAMESPACE = { "dif" => "http://gcmd.gsfc.nasa.gov/Aboutus/xml/dif/" }
    
    XPATH = "//dif:DIF"
    
    # Field Presets
    
    EXCLUDED = ["Fax", "Postal_Code", "Phone", "Multimedia_Sample", "Paleo_Temporal_Coverage"]
    
    RECOMMENDED = ["DIF_Creation_Date", "DIF_Revision_History", "Future_DIF_Review_Date", "IDN_Node", "Keyword", "Last_DIF_Revision_Date", "Multimedia_Sample", "Parent_DIF", "Reference"]

    REQUIRED = ["Data_Center", "Entry_ID", "Entry_Title", "ISO_Topic_Category", "Metadata_Name", "Metadata_Version", "Parameters", "Summary"]
    
    attr_accessor :document, :schema
    
    def initialize( dif_xml=nil )
      self.schema = Gcmd::Schema.new
      self.document = load_xml( dif_xml ) unless dif_xml.nil?
    end
   
    # Loads the source as a Nokogiri::XML::Document
    # and makes the necesarry method calls for conversion.
    # returns an array of Hash documents.
   
    def build_hash_documents( dif_xml=nil )
      difs = []
      self.document = load_xml( dif_xml ) unless dif_xml.nil?
      
      unless document.nil?
        difs = document_to_object
      else
        raise ArgumentError, "No XML provided!"
      end

      difs
    end
    
    # Detect documents in the XML based on xpath information and calls
    # the parser on each document. This returns an Array of Hash objects.
  
    def document_to_object( xpath = XPATH, namespace = NAMESPACE)
      obj = []
        
      document.xpath( xpath, namespace ).each do | node |
        hash_data = hash_from_xml( node.children )
        obj << hash_data
      end
        
      obj
    end
    
    # Recursive method that walks the XML tree and generates an output Hash
    # @see #handle_multiples
    
    def hash_from_xml( element )
      result = {}
      
      element.each do |node|
        unless excluded?( node.name )
          if unbounded?( node.name )
            result[ node.name ] = handle_multiples( result[ node.name ], node.children )
          else
            
            if node.children.children.any?
              result[ node.name ] = hash_from_xml( node.children )
            else
              result[ node.name ] = node.content
            end
            
          end
        end
      end
      
      result
    end
    
    def handle_multiples( array, element )
    end
    
    protected
    
    def excluded?( key )
      EXCLUDED.include?( key )
    end
    
    def unbounded?( key )
      schema.unbounded.include?( key )
    end
    
  end
  
end
