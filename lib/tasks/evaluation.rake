# encoding: utf-8

namespace :evaluation do

  # Usage
  # bundle exec rake evaluation:utility
  task :utility => :environment do
    printTitle("Calculating Breeze's R-score utility metric")
    require 'descriptive_statistics'

    usersData = []
    breezeSettings = {:alpha => 3.5, :d => 1}

    Evaluation.all.each do |e|
      userData = {}
      data = JSON.parse(e.data)

      #Experiment A: recommendations taking into account user profile (e.g. home page)
      dataA = data["A"]
      userData[:scoresRecA] = dataA["recommendationsA"].map{|loProfile| dataA["relevances"][loProfile["id_repository"]]}
      userData[:scoresRandomA] = dataA["randomA"].map{|loProfile| dataA["relevances"][loProfile["id_repository"]]}
      userData[:breezeScoreRecA] = breeze_rscore(userData[:scoresRecA],breezeSettings)
      userData[:breezeScoreRandomA] = breeze_rscore(userData[:scoresRandomA],breezeSettings)

      #Experiment B: recommendations taking into account lo profile without user profile (e.g. non logged user seeing a resource)
      dataB = data["B"]
      userData[:scoresRecB] = dataB["recommendationsB"].map{|loProfile| dataB["relevances"][loProfile["id_repository"]]}
      userData[:scoresRandomB] = dataB["randomB"].map{|loProfile| dataB["relevances"][loProfile["id_repository"]]}
      userData[:breezeScoreRecB] = breeze_rscore(userData[:scoresRecB],breezeSettings)
      userData[:breezeScoreRandomB] = breeze_rscore(userData[:scoresRandomB],breezeSettings)

      usersData << userData
    end

    #Generate excel file with results
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => "Recommender System Utility") do |sheet|
        rows = []
        rows << ["Recommender System Utility"]
        rowIndex = rows.length

        rows += Array.new(2 + usersData[0][:scoresRecA].length).map{|e| []}

        usersData.each_with_index do |userData,i|
          rows[rowIndex] += (["User " + (i+1).to_s] + Array.new(7))
          rows[rowIndex+1] += ["RecA","RandomA","RecB","RandomB","Breeze RecA","Breeze RandomA","Breeze RecB","Breeze RandomB"]
          userData[:scoresRecA].length.times do |j|
            rows[rowIndex+2+j] += [userData[:scoresRecA][j],userData[:scoresRandomA][j],userData[:scoresRecB][j],userData[:scoresRandomB][j]]
          end
          rows[rowIndex+2] += [userData[:breezeScoreRecA],userData[:breezeScoreRandomA],userData[:breezeScoreRecB],userData[:breezeScoreRandomB]]
        end

        rowIndex = rows.length
        rows += Array.new(13).map{|e| []}
        rows[rowIndex+1] += (["Experiment A"] + Array.new(3))
        rows[rowIndex+2] += ["Breeze Rec",nil,"Breeze Random",nil]
        rows[rowIndex+3] += ["M","SD","M","SD"]
        rows[rowIndex+4] += [usersData.map{|userData| userData[:breezeScoreRecA]}.mean.round(2),usersData.map{|userData| userData[:breezeScoreRecA]}.standard_deviation.round(3),usersData.map{|userData| userData[:breezeScoreRandomA]}.mean.round(2),usersData.map{|userData| userData[:breezeScoreRandomA]}.standard_deviation.round(3)]

        rows[rowIndex+6] += (["Experiment B"] + Array.new(3))
        rows[rowIndex+7] += ["Breeze Rec",nil,"Breeze Random",nil]
        rows[rowIndex+8] += ["M","SD","M","SD"]
        rows[rowIndex+9] += [usersData.map{|userData| userData[:breezeScoreRecB]}.mean.round(2),usersData.map{|userData| userData[:breezeScoreRecB]}.standard_deviation.round(3),usersData.map{|userData| userData[:breezeScoreRandomB]}.mean.round(2),usersData.map{|userData| userData[:breezeScoreRandomB]}.standard_deviation.round(3)]

        rows[rowIndex+10] += ["Breeze parameters"]
        rows[rowIndex+11] += ["d","Alpha"]
        rows[rowIndex+12] += [breezeSettings[:d],breezeSettings[:alpha]]

        rows.each do |row|
          sheet.add_row row
        end
      end
      p.serialize('evaluations/utility.xlsx')
    end

    puts("Task Finished. Results generated at evaluations/utility.xlsx")
  end

  # Usage
  # bundle exec rake evaluation:accuracy
  # Leave-one-out method: measure how often the left-out entity appeared in the top N recommendations
  task :accuracy => :environment do
    printTitle("Calculating Accuracy using leave-one-out")

    #Get users with more than 3 saved resources
    users = User.joins(:saved_items).group("users.id").having("count(los.id) > ?",3)

    #Recommender System settings
    rsSettings = {:preselection_filter_languages => true, :europeanars_database => {:preselection_size => 1000}, :rs_weights => {:los_score=>0.5, :us_score=>0.5, :quality_score=>0.0, :popularity_score=>0.0}, :los_weights => {:title=>0.2, :description=>0.15, :language=>0.5, :year=>0.15}, :us_weights => {:language=>0.2, :los=>0.8}, :rs_filters => {:los_score=>0, :us_score=>0, :quality_score=>0, :popularity_score=>0}, :us_filters => {:language=>0, :los=>0}}

    #N values
    ns = [1,3,5,10,20,500]

    results = {}

    ns.each do |n|
      results[n.to_s] = {:attempts => 0, :successes => 0, :accuracy => 0}
      users.each do |user|
        los = user.saved_items
        los.each do |lo|
          #Leave lo out and see if it appears on the n recommendations
          userProfile = user.profile({:n => los.length})
          userProfile[:los] = userProfile[:los].reject{|loProfile| loProfile[:id_repository]==lo.id_europeana}
          recommendations = RecommenderSystem.suggestions({:n => n, :settings => rsSettings, :user_profile => userProfile, :user_settings => {}, :max_user_los => los.length})
          success = recommendations.select{|loProfile| loProfile[:id_repository]==lo.id_europeana}.length > 0
          results[n.to_s][:attempts] += 1
          results[n.to_s][:successes] += 1 if success
        end
      end
      results[n.to_s][:accuracy] = (results[n.to_s][:successes]/results[n.to_s][:attempts].to_f * 100).round(1)
    end

    #Generate excel file with results
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => "Recommender System Accuracy") do |sheet|
        rows = []
        rows << ["Recommender System Accuracy"]
        rows << []
        rows << ["n","accuracy","attempts","succcesses"]
        
        rows += Array.new(ns.length).map{|e| []}
        ns.each do |n|
          rows << [n,results[n.to_s][:accuracy],results[n.to_s][:attempts],results[n.to_s][:successes]]
        end

        rows.each do |row|
          sheet.add_row row
        end
      end
      p.serialize('evaluations/accuracy.xlsx')
    end

    puts("Task Finished. Results generated at evaluations/accuracy.xlsx")
  end

  private

  ####################
  # Metrics
  ####################

  def breeze_rscore(scores,options)
    score = 0
    max_score = 0
    alpha = options[:alpha] || 1.5 #Half-life parameter which controls exponential decline of the value of positions.
    d = options[:d] || 1 #Breeze's don't care threshold.
    scores.each_with_index do |s,j|
      score += ([s-d,0].max)/(2 ** ((j-1)/(alpha-1)))
      max_score += ([5-d,0].max)/(2 ** ((j-1)/(alpha-1)))
    end
    #Normalization
    score/max_score.to_f
  end

  ####################
  # Task Utils
  ####################

  def printTitle(title)
    unless title.nil?
      puts "#####################################"
      puts title
      puts "#####################################"
    end
  end

  def printSeparator
    puts ""
    puts "--------------------------------------------------------------"
    puts ""
  end

end

