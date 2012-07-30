require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "Sinatra App" do
  it "should respond to /enter_scores" do
    get '/enter_scores'
    last_response.should be_ok
  end
  
  module Scores
    def add_score(winner, loser, pf, pa) 
    end
  end
  
end


describe "Scores" do
  it "should have an 'add score(winner, loser, PF, PA)' method" do
    Scores.add_score('', '', 0, 0)
  end
  
  it 'there should be no scores entered for TEST' do
    db = get_db
    coll = db.collection("teams")
    coll.remove({"name" => "TEST_winner"})
    coll.save({"name" => "TEST_winner", "wins" => [], "losses" => []})
    
    coll.remove({"name" => "TEST_loser"})
    coll.save({"name" => "TEST_loser", "wins" => [], "losses" => []})
    
    
    team_winner = coll.find_one({"name" => "TEST_winner"})
    
    team_winner["wins"].count.should == 0
    team_winner["losses"].count.should == 0
    
    team_loser = coll.find_one({"name" => "TEST_loser"})
    
    team_loser["wins"].count.should == 0
    team_loser["losses"].count.should == 0
  end
  
  it 'there should be one win after entering a score for test' do
    Scores.add_score('TEST_winner', '', 0, 0)
    
    db = get_db
    coll = db.collection("teams")
    team = coll.find_one({"name" => "TEST_winner"})
    
    team["wins"].count.should == 1
  end
  
  it 'should have the name of the losing team in there' do
    Scores.add_score('TEST_winner', 'Royals', 0, 0)
    
    db = get_db
    coll = db.collection("teams")
    team = coll.find_one({"name" => "TEST"})
    
    team["wins"][1]["name"].should == "Royals"
  end
  
  it 'should have the scores in there' do
    Scores.add_score('TEST_winner', 'Royals', 12, 5)
    
    db = get_db
    coll = db.collection("teams")
    team = coll.find_one({"name" => "TEST_winner"})
    
    team["wins"][2]["PF"].should == 12
    team["wins"][2]["PA"].should == 5
  end
  
  it 'there should be one loss after entering a score for test' do
    Scores.add_score('TEST', 'TEST_loser', 0, 0)
    
    db = get_db
    coll = db.collection("teams")
    team = coll.find_one({"name" => "TEST_loser"})
    
    team["losses"].count.should == 1
  end
  
  it 'should have the name of the winning team in there' do
    Scores.add_score('TEST_winner', 'TEST_loser', 0, 0)
    
    db = get_db
    coll = db.collection("teams")
    team = coll.find_one({"name" => "TEST_loser"})

    team["losses"][1]["name"].should == "TEST_winner"
  end
  
  it 'should have the scores in there for the loss' do
    Scores.add_score('TEST_winner', 'TEST_loser', 128, 52)
    
    db = get_db
    coll = db.collection("teams")
    team = coll.find_one({"name" => "TEST_loser"})
    
    team["losses"][2]["PF"].should == 128
    team["losses"][2]["PA"].should == 52
  end
  
end