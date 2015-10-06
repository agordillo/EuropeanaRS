class LosController < ApplicationController

  def show
    @lo = Lo.find_by_id(params[:id])
    redirect_to(view_context.home_path, :alert => 'Learning Object Not Found') unless @lo
    @suggestions = RecommenderSystem.suggestions({:n => 20, :user_profile => current_user_profile, :lo_profile => @lo.profile})
  end

end