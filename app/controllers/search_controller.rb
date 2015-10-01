class SearchController < ApplicationController

  def search
    @results = (Lo.search params[:query], :page => 1, :per_page => 24)
  end

end