require "spec_helper"
require "gcmd/dif_importer"

require "nokogiri"

describe Gcmd::DifImporter do
  
  subject do
    Gcmd::DifImporter.new( "spec/data/dif_record.xml" )
  end
  
  context "Importing XML" do
    
    it "should have a document if initialized with a XML source" do
      subject.document.should be_a_kind_of( Nokogiri::XML::Document )
    end
    
    it "shouldn't have a document if initialized without a XML source" do
      importer = Gcmd::DifImporter.new
      importer.document.should be( nil )
    end
    
    context "#build_hash_documents" do
      
      it "should return an array" do
        subject.build_hash_documents.should be_a_kind_of( Array )
      end
      
      it "should set document if provided with a XML source" do
        importer = Gcmd::DifImporter.new
        importer.build_hash_documents( "spec/data/dif_record.xml" )
        subject.document.should be_a_kind_of( Nokogiri::XML::Document )
      end
      
      it "should raise an argument error if no document is found" do
        importer = Gcmd::DifImporter.new
        expect{ importer.build_hash_documents }.to raise_error( ArgumentError )
      end
      
    end
    
    context "#document_to_object" do
      
      it "should return an array" do
        subject.document_to_object.should be_a_kind_of( Array )
      end
      
      it "the result array should consist of Hashes" do
        subject.document_to_object.each do | doc |
          doc.should be_a_kind_of( Hash )
        end
      end
      
    end
    
    context "#hash_from_xml" do
      
      it "should return a Hash" do
        subject.hash_from_xml( "" ).should be_a_kind_of( Hash )
      end
        
    end
    
  end
  
  context "Import Options" do
    
    context "#excluded?" do
      
      it "should return true if element is declared in Gcmd::DifImporter::EXCLUDED" do
        subject.send( :excluded?, "Fax" ).should be( true )
      end
      
    end
    
    context "#unbound?" do
      
      it "should return true if element is defined as unbounded in schema" do
        subject.send( :unbound?, "Role" ).should be( true )
      end
      
    end
    
  end
  
end
