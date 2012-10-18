require "nokogiri"
require "json"

module Gcmd
  module KeywordParser
    
    #def json_concepts( rdf_data )
    #  rdf_json = []
    #  
    #  rdf_data.xpath("//skos:Concept").each do | concept |
    #    
    #      rdf_json <<  {
    #     
    #        :id => concept_id(concept),
    #        :label => concept_label(concept),
    #        :parent => concept_parent(concept),
    #        :title => parent_relation(rdf_data, concept),
    #        :ancestors => parent_relation(rdf_data, concept),
    #        :children => concept_children(concept),
    #        :node_type => concept_type(concept)
    #        
    #      } #unless concept_root?(concept) ## Uncomment if you don't want to capture the root concept
    #      
    #  end
    #  rdf_json
    #end
    
    def concept_id(concept)
      concept.xpath("@rdf:about").to_s
    end
    
    def concept_label(concept)
      concept.xpath(".//skos:prefLabel").inner_text
    end
     
    def concept_parent(concept)
      concept.xpath(".//skos:broader/@rdf:resource").to_s
    end
    
    def concept_children(concept)
      concept.xpath(".//skos:narrower/@rdf:resource").map{ |child| child.to_s}
    end
      
    def concept_type(concept)
      return "leaf" if concept_leaf?(concept)
      return "root" if concept_root?(concept)
      return "branch" if concept_branch?(concept)
      "unknown"
    end
    
    def concept_root?(concept)      
      return true if concept.xpath(".//skos:broader/@rdf:resource").to_s == ""        
      false      
    end
    
    def concept_leaf?(concept)
      return true unless concept.xpath(".//skos:narrower/@rdf:resource").map{ |child| child.to_s }.any?
      false
    end
    
    def concept_branch?(concept)
      return true unless concept_root?(concept) || concept_leaf?(concept)
      false
    end
      
    def lookup_concept(rdf, id)
      rdf.xpath("//skos:Concept[@rdf:about=\"#{id}\"]")      
    end
    
    def parent_relation(rdf, concept)
      relation = ""
      parent = concept_parent(concept)
      
      unless concept_root?(lookup_concept(rdf, parent))      
        relation = parent_relation(rdf, lookup_concept(rdf, parent)) + " < " + concept_label(concept)
      else
        relation += concept_label( concept )
      end
      
      relation
    end
    
    def dump_json( docs )
      my_file = File.open("JsonConcepts.json", "w") do |f|
        f.write(docs.to_json)
      end
    end
    
  end
end