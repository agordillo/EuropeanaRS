class UsersController < ApplicationController

  before_filter :authenticate_user!

  def profile
    render "show"
  end

end
  