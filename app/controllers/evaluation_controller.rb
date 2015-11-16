class EvaluationController < ApplicationController

  before_filter :authenticate_user!

  def start
    return redirect_to(view_context.home_path, :alert => "Evaluation not enabled in this EuropeanaRS instance.") unless EuropeanaRS::Application::config.evaluation
    
    evaluationStatus = current_user.evaluation.nil? ? "0" : current_user.evaluation.status
    return redirect_to(view_context.home_path, :alert => "Evaluation already sent. Thank you!") unless evaluationStatus != "Finished"

    return redirect_to(view_context.home_path, :alert => "You need to save at least 4 resources in your profile to carry out the evaluation.") unless current_user.saved_items.length > 3

    case evaluationStatus
    when "0"
      #Data for step1
      recommendationsS1 = RecommenderSystem.suggestions({:n => 6, :user_profile => current_user_profile, :user_settings => nil})
      randomS1 = Utils.getRandom({:n => 6})
      @itemsS1 = (recommendationsS1 + randomS1).shuffle
      render :step1
    when "1"
      #Data for step2
      @lo = getStep2Item
      recommendationsS2 = RecommenderSystem.suggestions({:n => 6, :user_profile => nil, :user_settings => nil, :lo_profile => @lo.profile})
      randomS2 = Utils.getRandom({:n => 6})
      @itemsS2 = (recommendationsS2 + randomS2).shuffle
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
    e = Evaluation.new
    #TODO...
    e.status = "1"
    e.save!
    redirect_to "/evaluation"
  end

  #Save step2
  def step2
    e = current_user.evaluation
    #TODO...
    e.status = "2"
    e.save!
    redirect_to "/evaluation"
  end

  #Save step3
  def step3
    e = current_user.evaluation
    #TODO...
    e.status = "Finished"
    e.save!
    return redirect_to(view_context.home_path, :alert => "Evaluation finished. Thank you for you collaboration!")
  end


  private

  def getStep2Item
    userProfile = current_user_profile
    loProfiles = current_user.saved_items.map{|lo| lo.profile}
    similarity = []

    loProfiles.each do |loProfile|
      similarity << RecommenderSystem.userProfileSimilarityScore(userProfile,loProfile)
    end

    return loProfiles[similarity.find_index(similarity.max)]
  end

end
  