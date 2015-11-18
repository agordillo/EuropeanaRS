class EvaluationController < ApplicationController

  before_filter :authenticate_user!

  def start
    return redirect_to(view_context.home_path, :alert => I18n.t("evaluation.messages.disabled")) unless EuropeanaRS::Application::config.evaluation
    
    evaluationStatus = current_user.evaluation.nil? ? "0" : current_user.evaluation.status
    return redirect_to(view_context.home_path, :notice => I18n.t("evaluation.messages.duplicated")) unless evaluationStatus != "Finished"

    return redirect_to(view_context.home_path, :alert => I18n.t("evaluation.messages.resources")) unless current_user.saved_items.length > 3

    #RS settings for the evaluation study
    rsSettings = {:preselection_filter_languages => true, :europeanars_database => {:preselection_size => 600}, :rs_weights => {:los_score=>0.5, :us_score=>0.5, :quality_score=>0.0, :popularity_score=>0.0}, :los_weights => {:title=>0.2, :description=>0.15, :language=>0.5, :year=>0.15}, :us_weights => {:language=>0.2, :los=>0.8}, :rs_filters => {:los_score=>0, :us_score=>0, :quality_score=>0, :popularity_score=>0}, :us_filters => {:language=>0, :los=>0}}

    case evaluationStatus
    when "0"
      #No data needed for step1
      render :step1
    when "1"
      #Data for step2
      rsSettingsA = rsSettings
      @recommendationsA = RecommenderSystem.suggestions({:n => 6, :settings => rsSettingsA, :user_profile => current_user.profile({:n => 5}), :user_settings => {}, :max_user_los => 5})
      @randomA = Utils.getRandom({:n => 6, :europeana_ids_to_avoid => @recommendationsA.map{|loProfile| loProfile[:id_repository]}})
      @itemsA = (@recommendationsA + @randomA).shuffle
      render :step2
    when "2"
      #Data for step3
      rsSettingsB = rsSettings.recursive_merge({:preselection_filter_languages => false})
      @lo = getBLo({:settings => rsSettingsB})
      @recommendationsB = RecommenderSystem.suggestions({:n => 6, :settings => rsSettingsB, :user_profile => nil, :user_settings => {}, :lo_profile => @lo.profile})
      @randomB = Utils.getRandom({:n => 6, :europeana_ids_to_avoid => @recommendationsB.map{|loProfile| loProfile[:id_repository]}})
      @itemsB = (@recommendationsB + @randomB).shuffle
      render :step3
    else
      return redirect_to(view_context.home_path, :alert => "Evaluation at wrong state. Please contact with the EuropeanaRS team.")
    end
  end

  #Save step1
  def step1
    e = Evaluation.new
    e.user_id = current_user.id
    e.status = "1"
    e.data = {}.to_json
    e.save!
    redirect_to "/evaluation"
  end

  #Save step2
  def step2
    dataA = JSON.parse(params["data"]) rescue {}
    #Data validation.
    errors = []
    errors << "Missing data" if dataA["recommendationsA"].blank? or dataA["randomA"].blank? or dataA["relevances"].blank?
    errors << "Incorrect number of items" if dataA["recommendationsA"].length!=6 or dataA["randomA"].length!=6
    errors << "Missing relevances" if dataA["relevances"].compact.length!=(dataA["recommendationsA"].length+dataA["randomA"].length)
    errors << "Incorrect relevances" unless dataA["recommendationsA"].map{|h| dataA["relevances"][h["id_repository"]]}.select{|r| r.nil?}.blank? and dataA["randomA"].map{|h| dataA["relevances"][h["id_repository"]]}.select{|r| r.nil?}.blank?

    unless errors.blank?
      return redirect_to("/evaluation", :alert => errors.first)
    end

    data = {}
    data["A"] = dataA
    data["user_profile"] = current_user.profile({:n => 10})

    e = current_user.evaluation
    e.data = data.to_json
    e.status = "2"
    e.save!
    redirect_to "/evaluation"
  end

  #Save step3
  def step3
    dataB = JSON.parse(params["data"]) rescue {}
    #Data validation.
    errors = []
    errors << "Missing data" if dataB["recommendationsB"].blank? or dataB["randomB"].blank? or dataB["relevances"].blank?
    errors << "Incorrect number of items" if dataB["recommendationsB"].length!=6 or dataB["randomB"].length!=6
    errors << "Missing relevances" if dataB["relevances"].compact.length!=(dataB["recommendationsB"].length+dataB["randomB"].length)
    errors << "Incorrect relevances" unless dataB["recommendationsB"].map{|h| dataB["relevances"][h["id_repository"]]}.select{|r| r.nil?}.blank? and dataB["randomB"].map{|h| dataB["relevances"][h["id_repository"]]}.select{|r| r.nil?}.blank?

    unless errors.blank?
      return redirect_to("/evaluation", :alert => errors.first)
    end

    e = current_user.evaluation
    data = JSON.parse(e.data)
    data["B"] = dataB
    data["lo_profile"] = getBLo.profile

    e.data = data.to_json
    e.status = "Finished"
    e.save!

    redirect_to(view_context.home_path, :notice => I18n.t("evaluation.messages.success"))
  end


  private

  def getBLo(options={})
    userProfile = current_user.profile
    loProfiles = current_user.saved_items.map{|lo| lo.profile}
    similarity = []

    loProfiles.each do |loProfile|
      similarity << RecommenderSystem.userProfileSimilarityScore(userProfile,loProfile,options)
    end

    return current_user.saved_items[similarity.find_index(similarity.max)]
  end

end
  