class UsersController < ApplicationController

  before_filter :authenticate_user!

  def profile
    render "show"
  end

  def account
  end

  def settings
  end

  def favorites
  end

  def akeys
  end

end
  