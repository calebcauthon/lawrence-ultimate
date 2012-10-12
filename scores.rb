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
  
  def self.get_all_scores
    db = get_db
    coll = db.collection("teams")
    
    teams = coll.find
    
    scores = Array.new
    
    teams.each do |this_team|
      unless this_team['wins'].nil?
        wins = this_team['wins']
        wins.each do |this_win|
          this_win['winning_team_object'] = this_team
          this_win['winning_name'] = this_team['name']
          this_win['losing_name'] = this_win['name']
          this_win['winning_points'] = this_win['PF']
          this_win['losing_points']= this_win['PA']
          
          scores.push(this_win)      
        end                 
      end      
    end
    
    scores
  end
end