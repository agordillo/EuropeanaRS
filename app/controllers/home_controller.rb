class HomeController < ApplicationController

  def index
    @suggestions = RecommenderSystem.suggestions({:n => 20, :user_profile => current_user_profile, :user_settings => current_user_settings})
  end

end