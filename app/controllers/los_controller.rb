class LosController < ApplicationController

  def show
    @lo = Lo.find_by_id(params[:id])
    redirect_to(view_context.home_path, :alert => 'Learning Object Not Found') unless @lo
    @suggestions = (Lo.search "", :page => rand(8)+1, :per_page => 1000).sample(20)
  end

end