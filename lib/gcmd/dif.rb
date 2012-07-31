require "rubygems"
require "yajl/json_gem"
require "nokogiri"
require "open-uri"
require "uuidtools"

module Gcmd
  
  # DIF is a XML-based metadata specification used by NASA's Global Change Master Directory (GCMD)
  #
  # @see http://gcmd.gsfc.nasa.gov/User/difguide/difman.html DIF Guide
  # @see http://gcmd.nasa.gov/Aboutus/xml/dif/dif.xsd DIF XML Schema
  # @see http://gcmd.nasa.gov/Aboutus/ About GCDM
  #
  # Gcmd::Dif contains methods for
  # - loading DIF XML
  # - converting DIF XML to a Ruby Hash object
  # - exporting attributes Hash to DIF XML
  # - validating DIF XML
  #
  # @todo transforming DIF XML using XSLT
  #
  # DIF XML may contain a number of controlled vocabularies, used to be called "valids". 
  #
  # @author Ruben Dens
  # @author Conrad Helgeland
  #
  # [Project License]
  # This project is licensed under the {http://www.gnu.org/licenses/gpl.html GNU General Public License Version 3} (GPLv3)
  class Dif
    
    # 17 highly recommended DIF fields
    HIGHLY_RECOMMENDED = ["Access_Constraints", "Data_Resolution", "Data_Set_Citation", "Data_Set_Language",
      "Data_Set_Progress", "Distribution", "Sensor_Name", "Location", "Paleo_Temporal_Coverage", "Personnel", "Source_Name",
      "Project", "Quality", "Related_URL", "Spatial_Coverage", "Temporal_Coverage", "Use_Constraints"]
  
    # Excluded in JSON export
    EXCLUDED = ["Fax", "Postal_Code", "Phone", "Multimedia_Sample", "Paleo_Temporal_Coverage"]
    
    NAMESPACE = { "dif" => "http://gcmd.gsfc.nasa.gov/Aboutus/xml/dif/" }
    
    RECOMMENDED = ["DIF_Creation_Date", "DIF_Revision_History", "Future_DIF_Review_Date", "IDN_Node", "Keyword", "Last_DIF_Revision_Date", "Multimedia_Sample", "Parent_DIF", "Reference"]

    REQUIRED = ["Data_Center", "Entry_ID", "Entry_Title", "ISO_Topic_Category", "Metadata_Name", "Metadata_Version", "Parameters", "Summary"]
    
    ROLES = ["Investigator", "Technical Contact", "DIF Author"]
    
    VERSION = "9.8.3"
    
    WANTED_RECOMMENDED = ["DIF_Creation_Date", "IDN_Node", "Keyword", "Originating_Metadata_Node", "Parent_DIF", "Private"]

    XPATH = "//dif:DIF"
    
    XSD = "dif.xsd"
    
    XSD_URI = "http://gcmd.nasa.gov/Aboutus/xml/dif/dif.xsd"
    
    ####################################################################################################################
    
    # All 34 DIF fields
    FIELDS = REQUIRED + HIGHLY_RECOMMENDED + RECOMMENDED

    WANTED = REQUIRED + HIGHLY_RECOMMENDED - EXCLUDED + WANTED_RECOMMENDED
      
    # http://nokogiri.org/Nokogiri/XML/Document.html
    attr_accessor :document
    
    # Hash
    #attr_accessor :attributes
    
    attr_accessor :dif_xpath
  
    # Convert DIF XML to Ruby object
    # @todo use future #load
    def self.document_to_object(source, dif_xpath = XPATH)
      dif = self.new      
      
      dif.dif_xpath = dif_xpath
      dif.load_xml( source )  
      
      dif.document_to_object
    end
    
    # Convert DIF XML to JSON

    def self.to_json(source, dif_xpath = XPATH)
      JSON.pretty_generate(self.document_to_object(source, dif_xpath = XPATH))
    end
    
    # Import DIF XML and export to DIF XML

    def self.to_xml(source)
      dif = self.new
      dif.load_xml(source)
      dif.to_xml
    end
    
    def self.schema
      dif = self.new
      dif.schema
    end
    
    def self.empty_xml
      dif = self.new
      dif.to_xml
    end
    
    def self.empty_json
      dif = self.new
      dif.to_json
    end
    
    # Validate DIF XML

    def self.validate_xml(source, dif_xpath = XPATH)
      dif = self.new
      dif.dif_xpath = dif_xpath
      dif.load_xml( source )  
      dif.validate_xml
    end
    
    def self.empty_dif_xml(version=Gcmd::Dif::VERSION)
      xml = '<DIF xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="'+ Gcmd::Dif::NAMESPACE["dif"] +
            '"xsi:schemaLocation="'+ Gcmd::Dif::NAMESPACE["dif"] +' http://gcmd.nasa.gov/Aboutus/xml/dif/dif_v'+
            version +'.xsd"></DIF>'
    end
    
    def self.sequence(element = "DIF")
      sequence = []
      self.schema.xpath("//xs:element[@name = '#{element}']/xs:complexType/xs:sequence/xs:element").each do |element|
        minOccurs = element["minOccurs"]
        maxOccurs = element["maxOccurs"]
        ref = element["ref"]
        sequence << { ref => [minOccurs, maxOccurs]}
      end
      sequence
    end
    
    def attributes
      @attributes
      # if map.is a lambada?
    end
    
    def attributes=attributes
      @attributes=attributes
    end
    
    def initialize(attr = {})
      self.attributes = load(attr)
      self.document = Nokogiri::XML::Document.parse(self.class.empty_dif_xml)
    end
    
    def sequence(element)
      if "DIF" == element # optimization
        [{"Entry_ID"=>["1", "1"]}, {"Entry_Title"=>["1", "1"]}, {"Data_Set_Citation"=>["0", "unbounded"]}, {"Personnel"=>["0", "unbounded"]}, {"Discipline"=>["0", "unbounded"]}, {"Parameters"=>["1", "unbounded"]}, {"ISO_Topic_Category"=>["0", "unbounded"]}, {"Keyword"=>["0", "unbounded"]}, {"Sensor_Name"=>["0", "unbounded"]}, {"Source_Name"=>["0", "unbounded"]}, {"Temporal_Coverage"=>["0", "unbounded"]}, {"Paleo_Temporal_Coverage"=>["0", "unbounded"]}, {"Data_Set_Progress"=>["0", "1"]}, {"Spatial_Coverage"=>["0", "unbounded"]}, {"Location"=>["0", "unbounded"]}, {"Data_Resolution"=>["0", "unbounded"]}, {"Project"=>["0", "unbounded"]}, {"Quality"=>["0", "1"]}, {"Access_Constraints"=>["0", "1"]}, {"Use_Constraints"=>["0", "1"]}, {"Data_Set_Language"=>["0", "unbounded"]}, {"Originating_Center"=>["0", "1"]}, {"Data_Center"=>["1", "unbounded"]}, {"Distribution"=>["0", "unbounded"]}, {"Multimedia_Sample"=>["0", "unbounded"]}, {"Reference"=>["0", "unbounded"]}, {"Summary"=>["1", "1"]}, {"Related_URL"=>["0", "unbounded"]}, {"Parent_DIF"=>["0", "unbounded"]}, {"IDN_Node"=>["0", "unbounded"]}, {"Originating_Metadata_Node"=>["0", "1"]}, {"Metadata_Name"=>["1", "1"]}, {"Metadata_Version"=>["1", "1"]}, {"DIF_Creation_Date"=>["0", "1"]}, {"Last_DIF_Revision_Date"=>["0", "1"]}, {"DIF_Revision_History"=>["0", "1"]}, {"Future_DIF_Review_Date"=>["0", "1"]}, {"Private"=>["0", "1"]}]
      else
        self.class.sequence(element)
      end
    end
    
    # Calculate DIF element's multiplicity from XML Schema.
    # Cool, but a bit inefficient

    def multiplicity(name, parent = "DIF")
      res = schema.xpath("//xs:element[@name = '#{parent}']/xs:complexType/xs:sequence/xs:element[@ref='#{name}']", { "xs" => "http://www.w3.org/2001/XMLSchema"})
      unless res.size == 1
        raise "Unkown #{parent} subelement #{name}"
      end
      
      minOccurs = res.first.attr("minOccurs") # string
      maxOccurs = res.first.attr("maxOccurs") # string
      
      if maxOccurs == "unbounded"
        maxOccurs = -1
      end
      
      [minOccurs.to_i, maxOccurs.to_i]
    end

    def minOccurs(name)
      multiplicity(name)[0]
    end

    def maxOccurs(name)
      multiplicity(name)[1]
    end
    
    def load(hash, uri = false)
      if uri or hash =~ /^http(s)?\:\/\//
        hash = JSON.parse(open(hash))
      elsif hash.is_a? String
        hash = JSON.parse(hash)
      end
      json_skeleton.merge(hash)
    end

    # Load DIF XML from source (filename/string, or URI)

    def load_xml( source, uri = false )
      unless source.nil?
        if uri or source =~ /^http(s)?\:\/\//
          self.document = Nokogiri::XML::Document.parse( open( source ).read, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS )
        else
          if File.exists? source
            source = File.open( source )
          end
          
          self.document = Nokogiri::XML::Document.parse( source, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS )
          
        end
        
        o = document_to_object
        
        # Merge each DIF with the skeleton to get a complete tag representation
        
        #o.each_with_index do |item, index|
        #  o[index] = json_skeleton.merge(item)
        #end
        
        self.attributes = o
      end
    end

    # Load DIF JSON from source (filename/string, or URI)

    def load_json( source, uri = false )
      raise "Not implemented"
    end
    
    def schema
      Nokogiri::XML::Document.parse(xsd)   
    end
    
    def json_skeleton
      tpl = {}
      
      WANTED.each do |r|
        if unbounded? r
          tpl[r] = []
        else # either unbounded or 1
          tpl[r] = ""
        end
      end
      tpl
    end
    
    def skeleton(name)
      case name
        when "Data_Center" then { "Data_Center_Name" => { "Short_Name" => nil, "Long_Name" => nil}, "Data_Center_URL" => nil, "Data_Set_ID" => nil, "Personnel" => []}
        when "Personnel" then {
          "Contact_Address" => nil,
          "Email" => [],
          "Middle_Name" => nil,
          "Last_Name" => nil,
          "First_Name" => nil,
          "Role" => nil
        }
          
        when "Parameters" then {"Category"=>nil, "Term"=>nil, "Topic"=>nil}
      end
    end
    
    # Detect DIF tags in the XML
  
    def document_to_object
      obj = []
        
      document.xpath(dif_xpath, NAMESPACE) .each do | node |
        # node -> Nokogiri::XML::Element
        json_data = hash_from_nokogiri_xml_element( node.children )
        obj << json_data
      end
        
      obj  
    end
    
    def to_json
      attributes.to_json
    end
    
    def to_xml
      build_xml.to_xml
      
      #if attributes.is_a? Hash
      #  build_xml.to_xml
      #elsif attributes.is_a? Array
      #  raise "Cannot export multiple objects to DIF XML"
      #else
      #  raise "Cannot export #{attributes.inspect} to DIF XML"
      #end
    end
    
    # Return true if valid dif
    
    def valid?
      begin
        errors = validate
        return errors.size == 0
      rescue
        return false
      end
    end
    
    def validate
      # object, imported or exported?
      if self.document.is_a? Nokogiri::XML::Document
        validate_xml
      else
        []
      end
      
    end
    
    # Validate dif entries and catch errors in an array
    
    def validate_xml
      dif_errors = []
  
      schema = Nokogiri::XML::Schema( xsd )
      document.xpath(dif_xpath, NAMESPACE).each do | node |
        xml = node.to_s
        errs = schema.validate( Nokogiri::XML::Document.parse( xml ) )
        dif_errors << { "Entry_Title" => node.xpath(".//dif:Entry_Title", NAMESPACE).first.text, "Entry_ID" => node.xpath(".//dif:Entry_ID", NAMESPACE).first.text, :errors => errs } if errs.any?
      end
      dif_errors
    end
    
    def validate_to_xml(xpath=nil)
      schema = Nokogiri::XML::Schema( xsd )
      document = Nokogiri::XML::Document.parse(to_xml)
      errs = schema.validate( document )
    end
    
    # Xpath for dif nodes
    
    def dif_xpath
      #'//dif:DIF[dif:Entry_ID="org.polarresearch-452"]' #
      XPATH
    end
  
    # Get the dif schema in use
    # @todo Check metadata version in XML
    
    def xsd(version=VERSION)
      
      if version == VERSION
        xsd_filename = File.dirname(__FILE__) + "/#{XSD}"
      end
      
      if File.exists?( xsd_filename )
        return File.open( xsd_filename ).read
      else
        return open(XSD_URI)
      end
    end
    
    def attribute(name)
      dif = document_to_object
      
      if dif[name]
        return dif[name]
      else
        if unbounded? name
          []
        else
          ""
        end
      end
    end
    
    protected
    
    # BuildMultime
    # http://gcmd.nasa.gov/Aboutus/xml/dif/XML_Template.xml
    # http://nokogiri.rubyforge.org/nokogiri/Nokogiri/XML/Builder.html
    
    
    # <xs:element name="DIF">
    #   <xs:complexType>
    #      <xs:sequence>
    #         <xs:element ref="Entry_ID" minOccurs="1" maxOccurs="1"/>
    #         <xs:element ref="Entry_Title" minOccurs="1" maxOccurs="1"/>
    #         <xs:element ref="Data_Set_Citation" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Personnel" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Discipline" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Parameters" minOccurs="1" maxOccurs="unbounded"/>
    #         <xs:element ref="ISO_Topic_Category" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Keyword" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Sensor_Name" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Source_Name" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Temporal_Coverage" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Paleo_Temporal_Coverage" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Data_Set_Progress" minOccurs="0" maxOccurs="1"/>
    #         <xs:element ref="Spatial_Coverage" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Location" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Data_Resolution" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Project" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Quality" minOccurs="0" maxOccurs="1"/>
    #         <xs:element ref="Access_Constraints" minOccurs="0" maxOccurs="1"/>
    #         <xs:element ref="Use_Constraints" minOccurs="0" maxOccurs="1"/>
    #         <xs:element ref="Data_Set_Language" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Originating_Center" minOccurs="0" maxOccurs="1"/>
    #         <xs:element ref="Data_Center" minOccurs="1" maxOccurs="unbounded"/>
    #         <xs:element ref="Distribution" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Multimedia_Sample" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Reference" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Summary" minOccurs="1" maxOccurs="1"/>
    #         <xs:element ref="Related_URL" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Parent_DIF" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="IDN_Node" minOccurs="0" maxOccurs="unbounded"/>
    #         <xs:element ref="Originating_Metadata_Node" minOccurs="0" maxOccurs="1"/>
    #         <xs:element ref="Metadata_Name" minOccurs="1" maxOccurs="1"/>
    #         <xs:element ref="Metadata_Version" minOccurs="1" maxOccurs="1"/>
    #         <xs:element ref="DIF_Creation_Date" minOccurs="0" maxOccurs="1"/>
    #         <xs:element ref="Last_DIF_Revision_Date" minOccurs="0" maxOccurs="1"/>
    #         <xs:element ref="DIF_Revision_History" minOccurs="0" maxOccurs="1"/>
    #         <xs:element ref="Future_DIF_Review_Date" minOccurs="0" maxOccurs="1"/>
    #         <xs:element ref="Private" minOccurs="0" maxOccurs="1"/>
    #      </xs:sequence>
    #   </xs:complexType>
    # </xs:element>
    def build_xml
       
      builder = Nokogiri::XML::Builder.new(:encoding => "utf-8") do | xml |

        xml.DIF(:xmlns => NAMESPACE["dif"],
          :"xsi:schemaLocation" => "#{NAMESPACE["dif"]} #{NAMESPACE["dif"]}dif_v#{VERSION}.xsd",
          :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance") {
        
          xml.Entry_ID    attributes["Entry_ID"]
          
          xml.Entry_Title attributes["Entry_Title"]
          
          unless attributes["Data_Set_Citation"].nil?
            # Easy to create dynamic because all elements are optional strings
            sequence = ["Dataset_Creator", "Dataset_Editor", "Dataset_Title", "Dataset_Series_Name", "Dataset_Release_Date", "Dataset_Release_Place", "Dataset_Publisher", "Version", "Issue_Identification", "Data_Presentation_Form", "Other_Citation_Details", "Online_Resource"]              
            attributes["Data_Set_Citation"].each do | c |
              xml.Data_Set_Citation {
                sequence.each { | e | xml.send(e, c[e]) unless c[e].nil? }
              }
            end
          end
          
          # Watch out roles and emails may be repeated!
          attributes["Personnel"].each do |p|
            xml.Personnel {
              if p["Role"].nil?
                p["Role"] = [] 
              elsif p["Role"].is_a? String
                role = p["Role"]
                p["Role"] = [role]
              end

              if p["Email"].nil?
                p["Email"] = [] 
              elsif p["Email"].is_a? String
                email = p["Email"]
                p["Email"] = [email]
              end

              p["Role"].each do | role |
                xml.Role role
              end
              xml.First_Name p["First_Name"]
              xml.Middle_Name p["Middle_Name"]
              xml.Last_Name p["Last_Name"]

              p["Email"].each do | email|
                xml.Email email
              end
              
            }
            end
            #<xs:element name="Personnel">
            #  <xs:complexType>
            #     <xs:sequence>
            #        <xs:element ref="Role" minOccurs="1" maxOccurs="unbounded"/>
            #        <xs:element ref="First_Name" minOccurs="0" maxOccurs="1"/>
            #        <xs:element ref="Middle_Name" minOccurs="0" maxOccurs="1"/>
            #        <xs:element ref="Last_Name" minOccurs="1" maxOccurs="1"/>
            #        <xs:element ref="Email" minOccurs="0" maxOccurs="unbounded"/>
            #        <xs:element ref="Phone" minOccurs="0" maxOccurs="unbounded"/>
            #        <xs:element ref="Fax" minOccurs="0" maxOccurs="unbounded"/>
            #        <xs:element ref="Contact_Address" minOccurs="0" maxOccurs="1"/>
            #     </xs:sequence>
            #  </xs:complexType>
            #</xs:element>
            
          
        
          # Discipline {}
#          <xs:element name="Discipline">
#   <xs:complexType>
#      <xs:sequence>
#         <xs:element ref="Discipline_Name" minOccurs="1" maxOccurs="1"/>
#         <xs:element ref="Subdiscipline" minOccurs="0" maxOccurs="1"/>
#         <xs:element ref="Detailed_Subdiscipline" minOccurs="0" maxOccurs="1"/>
#      </xs:sequence>
#   </xs:complexType>
#</xs:element>
          
          # The <Parameters> field consists of a 7-level hierarchical classification of science keywords
          
            
          if attributes["Parameters"].nil?
            attributes["Parameters"] = [skeleton("Parameters")]
          end       
          attributes["Parameters"].each do | p |
            xml.Parameters {
            
              xml.Category p["Category"]
              xml.Topic p["Topic"]
              xml.Term p["Term"]
              xml.Variable_Level_1 p["Variable_Level_1"] if p["Variable_Level_1"]
              xml.Variable_Level_2 p["Variable_Level_2"] if p["Variable_Level_2"]
              xml.Variable_Level_3 p["Variable_Level_3"] if p["Variable_Level_3"]
              xml.Detailed_Variable p["Detailed_Variable"] if p["Detailed_Variable"]              
            }
          end
            
          
          #The <ISO_Topic_Category> field is used to identify the keywords in the ISO 19115 - Geographic Information Metadata (http://www.isotc211.org/) 
          unless attributes["ISO_Topic_Category"].any?
            attributes["ISO_Topic_Category"] = [""] # Required element
          end         
          attributes["ISO_Topic_Category"].each do | tc|
            xml.ISO_Topic_Category tc
          end
          
          attributes["Keyword"].each do |k|
            xml.Keyword k
          end
          

         #<xs:element ref="Sensor_Name" minOccurs="0" maxOccurs="unbounded"/>
          attributes["Sensor_Name"].each do |sensor|
            
            xml.Sensor_Name {
              xml.Short_Name sensor["Short_Name"] 
              xml.Long_Name sensor["Long_Name"]
            }
          
          end
          
           #<xs:element ref="Source_Name" minOccurs="0" maxOccurs="unbounded"/>
          attributes["Source_Name"].each do |source|
            
            xml.Source_Name {
              xml.Short_Name source["Short_Name"] 
              xml.Long_Name source["Long_Name"]
            }
          
          end

          #        
          # <xs:element ref="Temporal_Coverage" minOccurs="0" maxOccurs="unbounded"/>
          attributes["Temporal_Coverage"].each do | t |
            xml.Temporal_Coverage {
              xml.Start_Date t["Start_Date"]
              xml.Stop_Date t["Stop_Date"]
              
            }
          end
            
          #<xs:element ref="Paleo_Temporal_Coverage" minOccurs="0" maxOccurs="unbounded"/>

                   
          #<xs:element ref="Data_Set_Progress" minOccurs="0" maxOccurs="1"/>
          xml.Data_Set_Progress attributes["Data_Set_Progress"]
          
           #<xs:element ref="Spatial_Coverage" minOccurs="0" maxOccurs="unbounded"/>
          attributes["Spatial_Coverage"].each do | s |
            xml.Spatial_Coverage {
              xml.Southernmost_Latitude s["Southernmost_Latitude"]
              xml.Northernmost_Latitude s["Northernmost_Latitude"]
              xml.Westernmost_Longitude s["Westernmost_Longitude"]
              xml.Easternmost_Longitude s["Easternmost_Longitude"]
            }
          end
          
          #<xs:element ref="Location" minOccurs="0" maxOccurs="unbounded"/>
          attributes["Location"].each do | location |
            xml.Location {
              xml.Location_Category location["Location_Category"]
              xml.Location_Type location["Location_Type"] if location["Location_Type"]
              xml.Location_Subregion1 location["Location_Subregion1"] if location["Location_Subregion1"]
              xml.Location_Subregion2 location["Location_Subregion2"] if location["Location_Subregion2"]
              xml.Location_Subregion3 location["Location_Subregion3"] if location["Location_Subregion3"]
              xml.Detailed_Location location["Detailed_Location"] if location["Detailed_Location"]
            }             
          end
          
          #<xs:element ref="Data_Resolution" minOccurs="0" maxOccurs="unbounded"/>
          attributes["Data_Resolution"].each do | data_resolution |
            xml.Latitude_Resolution data_resolution["Latitude_Resolution"] if data_resolution.key? "Latitude_Resolution"
            xml.Longitude_Resolution data_resolution["Longitude_Resolution"] if data_resolution.key? "Longitude_Resolution"
            
            #<xs:element ref="Horizontal_Resolution_Range" minOccurs="0" maxOccurs="1"/>
            #<xs:element ref="Vertical_Resolution" minOccurs="0" maxOccurs="1"/>
            #<xs:element ref="Vertical_Resolution_Range" minOccurs="0" maxOccurs="1"/>
            #<xs:element ref="Temporal_Resolution" minOccurs="0" maxOccurs="1"/>
            #<xs:element ref="Temporal_Resolution_Range" minOccurs="0" maxOccurs="1"/>
            
          end
          
          #<xs:element ref="Project" minOccurs="0" maxOccurs="unbounded"/>
          attributes["Project"].each do | project |
             xml.Project {
              xml.Short_Name project["Short_Name"] 
              xml.Long_Name project["Long_Name"]
            }
          end

          
          xml.Quality attributes["Quality"]
          
          xml.Access_Constraints attributes["Access_Constraints"]
          
          xml.Use_Constraints attributes["Use_Constraints"]
          
          attributes["Data_Set_Language"].each do | language |
              xml.Data_Set_Language language
          end
          
          xml.Originating_Center attributes["Originating_Center"]
          
          # Data_Center
          unless attributes["Data_Center"].any?
            attributes["Data_Center"] = [skeleton("Data_Center")]
          end
          attributes["Data_Center"].each do | data_center |
          
          
          
          xml.Data_Center {
            
            xml.Data_Center_Name {
              xml.Short_Name data_center["Data_Center_Name"]["Short_Name"]  if data_center["Data_Center_Name"]
              xml.Long_Name data_center["Data_Center_Name"]["Long_Name"] if data_center["Data_Center_Name"]
            }
            
            xml.Data_Center_URL data_center["Data_Center_URL"]
            xml.Data_Set_ID data_center["Data_Set_ID"]
            
            build_personnel(data_center["Personnel"], xml)
            

          }
          end
          
          attributes["Distribution"].each do | distribution |
            xml.Distribution_Media distribution["Distribution_Media"]
            xml.Distribution_Size distribution["Distribution_Size"]
            xml.Distribution_Format distribution["Distribution_Format"]
          end
  
          # Reference []
          
#          <xs:element name="Reference">
#   <xs:complexType mixed="true">
#      <xs:sequence>
#         <xs:element ref="Author" minOccurs="0" maxOccurs="1"/>
#         <xs:element ref="Publication_Date" minOccurs="0" maxOccurs="1"/>
#         <xs:element ref="Title" minOccurs="0" maxOccurs="1"/>
#         <xs:element ref="Series" minOccurs="0" maxOccurs="1"/>
#         <xs:element ref="Edition" minOccurs="0" maxOccurs="1"/>
#         <xs:element ref="Volume" minOccurs="0" maxOccurs="1"/>
#         <xs:element ref="Issue" minOccurs="0" maxOccurs="1"/>
#         <xs:element ref="Report_Number" minOccurs="0" maxOccurs="1"/>
#         <xs:element ref="Publication_Place" minOccurs="0" maxOccurs="1"/>
#         <xs:element ref="Publisher" minOccurs="0" maxOccurs="1"/>
#         <xs:element ref="Pages" minOccurs="0" maxOccurs="1"/>
#         <xs:element ref="ISBN" minOccurs="0" maxOccurs="1"/>
#         <xs:element ref="DOI" minOccurs="0" maxOccurs="1"/>
#         <xs:element ref="Online_Resource" minOccurs="0" maxOccurs="1"/>
#         <xs:element ref="Other_Reference_Details" minOccurs="0" maxOccurs="1"/>
#      </xs:sequence>
#   </xs:complexType>
#</xs:element>

          if attributes["Summary"]["Abstract"].nil?
            xml.Summary {
              xml.Abstract attributes["Summary"]
              xml.Purpose nil
            }
          else
            xml.Summary {
              xml.Abstract attributes["Summary"]["Abstract"]
              xml.Purpose attributes["Summary"]["Purpose"]
            }
          end
          
    
          attributes["Related_URL"].each do | related_url |
            
          
          xml.Related_URL {
            unless related_url["URL_Content_Type"].nil?
              xml.URL_Content_Type {
                xml.Type related_url["URL_Content_Type"]["Type"] unless related_url["URL_Content_Type"]["Type"].nil?
                xml.Subtype related_url["URL_Content_Type"]["Subtype"] unless related_url["URL_Content_Type"]["Subtype"].nil?
              }
            end

            if related_url["URL"].is_a? String
              related_url["URL"] = [related_url["URL"]]
            end
            related_url["URL"].each do | url |
              xml.URL url
            end
            xml.Description related_url["Description"]
          }
          end
          
      
          attributes["Parent_DIF"].each do | parent_dif |
            xml.Parent_DIF parent_dif
          end
 
          attributes["IDN_Node"].each do | idn_node |
            xml.IDN_Node {
              xml.Short_Name idn_node["Short_Name"]
              xml.Long_Name idn_node["Long_Name"]
            }
          end
          
          xml.Originating_Metadata_Node attributes["Originating_Metadata_Node"]
          
          xml.Metadata_Name "CEOS IDN DIF"
          
          xml.Metadata_Version VERSION
          
          xml.DIF_Creation_Date attributes["DIF_Creation_Date"]
          
          xml.Last_DIF_Revision_Date attributes["Last_DIF_Revision_Date"]
          
          xml.DIF_Revision_History attributes["DIF_Revision_History"]
          
          xml.Future_DIF_Review_Date attributes["Future_DIF_Review_Date"]
          
          xml.Private attributes["Private"]
        }
      end
  
      builder
    end

    def build_personnel(personnel, xml)
           personnel.each do |p|
            xml.Personnel {
              if p["Role"].nil?
                p["Role"] = [] 
              elsif p["Role"].is_a? String
                role = p["Role"]
                p["Role"] = [role]
              end

              if p["Email"].nil?
                p["Email"] = [] 
              elsif p["Email"].is_a? String
                email = p["Email"]
                p["Email"] = [email]
              end

              p["Role"].each do | role |
                xml.Role role
              end
              xml.First_Name p["First_Name"]
              xml.Middle_Name p["Middle_Name"]
              xml.Last_Name p["Last_Name"]

              p["Email"].each do | email|
                xml.Email email
              end
              
            }
            end
    end
    #
    # Converts simple XML documents into JSON by calling itself recursively
    # @see #document_to_object for usage
    
    def hash_from_nokogiri_xml_element ( elmt )
      json_document = {}
      elmt.each do | node |
  
        unless exclude? node.name
        
          dif_multiples( json_document, node)
        
          if node.children.children.any?
            if json_document.has_key?( node.name )
              json_document[ node.name ] = handle_multiple_occurrences( json_document, node )
            else
              json_document[ node.name ] = hash_from_nokogiri_xml_element( node.children )
            end
          else            
            if json_document.has_key?( node.name )
              if json_document[ node.name ].is_a?( Array )
                json_document[ node.name ].push( node.content )
              else
                data = []
                data.push( json_document[ node.name ] )
                data.push( node.content )
                json_document[ node.name ] = data
              end
            else
              json_document[ node.name ] = node.content
            end  
            
          end
        end
      end      
      json_document
    end
    
  
    #
    # For the unbounded DIF elements define an array to hold all the values even if there is only one occurrence
    #
    # the elegant way would be to look up multiplicity in the xml schema...
    # OR: explicit define multiplicity = 1 (fewer)
    def dif_multiples( json_document, node)
      unbounded.each do | multi |
        if multi == node.name
          unless json_document.has_key?( node.name )
            json_document[ node.name ] = []
          end
        end
      end
    end
    
  
    #
    # In case of multiple element occurrences create an array for the values
    # and save them with one JSON key (This prevents overwriting of re-occurring elements)
    #
  
    def handle_multiple_occurrences( json_document, node )
      occurrences = []
      if json_document[ node.name ].is_a?( Array )
        occurrences = json_document[ node.name ]
      else
        unless json_document[ node.name ].nil?
          occurrences.push( json_document[ node.name ] )
        end
      end
      occurrences.push( hash_from_nokogiri_xml_element( node.children ) )
    end
    
    def exclude? key
      EXCLUDED.include? key
    end
    
    def unbounded
      ["Data_Set_Citation","Personnel","Discipline","Parameters","ISO_Topic_Category","Keyword","Sensor_Name",
      "Source_Name","Temporal_Coverage","Paleo_Temporal_Coverage","Spatial_Coverage","Location","Data_Resolution",
      "Project","Data_Set_Language","Data_Center","Distribution","Multimedia_Sample","Reference","Related_URL",
      "Parent_DIF","IDN_Node","Role","Email","Phone","Fax","Address","Chronostratigraphic_Unit","Data_Set_ID",
      "Personnel","URL"]
    end
    
    def unbounded? name
      unbounded.include? name
    end
    
    def schema_element_occurs(max_or_min="max", occurs="unbounded")
      list = []
      unless ["max", "min"].include? max_or_min
        raise "Argument error"
      end
      ng = Nokogiri::XML::Document.parse(xsd)     
      res = ng.xpath("//xs:element[@#{max_or_min}Occurs='#{occurs}']/@ref", { "xs" => "http://www.w3.org/2001/XMLSchema"})
      res.each do | ref |
        list << ref.chomp
      end
      list.sort
    end  
  end
end
