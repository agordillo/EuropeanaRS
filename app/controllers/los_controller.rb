class LosController < ApplicationController

  def index
    @los = Lo.search ""
    @los = @los.first(100)
  end

end