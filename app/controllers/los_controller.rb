class LosController < ApplicationController

  def show
  	@lo = Lo.find(params[:id])
  	 @suggestions = (Lo.search "", :page => rand(8)+1, :per_page => 1000).sample(20)
  end

end