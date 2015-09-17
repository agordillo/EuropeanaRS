class LosController < ApplicationController
  
	def index
		@los = Lo.search ""
	end

end