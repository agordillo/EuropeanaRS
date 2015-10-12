class UsersController < ApplicationController

  before_filter :authenticate_user!

  def profile
    render "show"
  end

  def account
  end

  #GET /settings
  def settings
    @user_settings = current_user_settings
  end

  #POST /settings
  def update_settings
    flash[:notice] = I18n.t("profile.settings.notifications.success.generic");
    # flash[:alert] = I18n.t("profile.settings.notifications.errors.generic");
    redirect_to "/settings"
  end

  def favorites
  end

  def akeys
  end

end
  