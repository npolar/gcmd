  concepts = Gcmd::Concepts.new
  
  Gcmd::Concepts::schemas.each do |schema|
    map "/#{schema}" do

      
      gcmd_concept = lambda {|env|
        q = Rack::Request.new(env)["q"]
        [200, {"Content-Type" => "application/json"},[concepts.filter(schema, q).to_json]]
      }
      #use Npolar::Rack::Solrizer, :core => ""
      run gcmd_concept
      
    end
  end