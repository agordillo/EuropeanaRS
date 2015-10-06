class HomeController < ApplicationController

  def index
    @suggestions = RecommenderSystem.suggestions({:n => 20, :user_profile => current_user_profile})
  end

end