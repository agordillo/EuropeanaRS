class HomeController < ApplicationController

  def index
    @suggestions = (Lo.search "", :page => rand(8), :per_page => 1000).sample(20)
  end

end