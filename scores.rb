module Scores
  
  def self.add_score(winner, loser, pf, pa)
    db = get_db
    coll = db.collection("teams")

    winning_team = coll.find_one({"name" => winner})
        
    unless(winning_team.nil? || winning_team["wins"].nil?)
      winning_team["wins"].push({
        "name" => loser,
        "PF" => pf.to_i,
        "PA" => pa.to_i
      })
      coll.save(winning_team)
    end
    
    losing_team = coll.find_one({"name" => loser})
      
    unless(losing_team.nil?)
      losing_team["losses"].push({
        "name" => winner,
        "PF" => pf.to_i,
        "PA" => pa.to_i
      })
      coll.save(losing_team)
    end    
    
  end
end