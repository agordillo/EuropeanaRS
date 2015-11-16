class EvaluationController < ApplicationController

  before_filter :authenticate_user!

  def start
    return redirect_to(view_context.home_path, :alert => "Evaluation not enabled in this EuropeanaRS instance.") unless EuropeanaRS::Application::config.evaluation
    
    evaluationStatus = current_user.evaluation.nil? ? "0" : current_user.evaluation.status
    return redirect_to(view_context.home_path, :notice => "Evaluation already sent. Thank you!") unless evaluationStatus != "Finished"

    return redirect_to(view_context.home_path, :alert => "You need to save at least 4 resources in your profile to carry out the evaluation.") unless current_user.saved_items.length > 3

    case evaluationStatus
    when "0"
      #Data for step1
      @recommendationsS1 = RecommenderSystem.suggestions({:n => 6, :user_profile => current_user.profile({:n => 5}), :user_settings => nil, :max_user_los => 5})
      @randomS1 = Utils.getRandom({:n => 6})
      @itemsS1 = (@recommendationsS1 + @randomS1).shuffle.first(2) #TODO REMOVE
      render :step1
    when "1"
      #Data for step2
      @lo = getStep2Lo
      recommendationsS2 = RecommenderSystem.suggestions({:n => 6, :user_profile => nil, :user_settings => nil, :lo_profile => @lo.profile})
      randomS2 = Utils.getRandom({:n => 6})
      @itemsS2 = (recommendationsS2 + randomS2).shuffle.first(2) #TODO REMOVE
      render :step2
    when "2"
      #No data needed for step3
      render :step3
    else
      return redirect_to(view_context.home_path, :alert => "Evaluation at wrong state. Please contact with the EuropeanaRS team.")
    end
  end

  #Save step1
  def step1
    dataStep1 = JSON.parse(params["data"]) rescue {}
    #TODO. Data validation.

    data = {}
    data["step1"] = dataStep1
    data["user_profile"] = current_user.profile({:n => 10})

    e = Evaluation.new
    e.user_id = current_user.id
    e.data = data.to_json
    e.status = "1"
    e.save!
    redirect_to "/evaluation"
  end

  #Save step2
  def step2
    dataStep2 = JSON.parse(params["data"]) rescue {}
    #TODO. Data validation.

    e = current_user.evaluation
    data = JSON.parse(e.data)
    data["step2"] = dataStep2
    data["lo_profile"] = getStep2Lo.profile

    e.data = data.to_json
    e.status = "2"
    e.save!
    redirect_to "/evaluation"
  end

  #Save step3
  def step3
    e = current_user.evaluation
    e.status = "Finished"
    e.save!
    return redirect_to(view_context.home_path, :notice => "Evaluation finished. Thank you for you collaboration!")
  end


  private

  def getStep2Lo
    userProfile = current_user.profile
    loProfiles = current_user.saved_items.map{|lo| lo.profile}
    similarity = []

    loProfiles.each do |loProfile|
      similarity << RecommenderSystem.userProfileSimilarityScore(userProfile,loProfile)
    end

    return current_user.saved_items[similarity.find_index(similarity.max)]
  end

end
  