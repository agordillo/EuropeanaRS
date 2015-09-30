class HomeController < ApplicationController

  def index
    @suggestions = (Lo.search "").sample(20)
  end

end