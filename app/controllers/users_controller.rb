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
    current_user.settings = params["user_settings"] unless params["user_settings"].blank? 

    if !params["user_settings"].blank? and current_user.save
      flash[:notice] = I18n.t("profile.settings.notifications.success.generic");
    else
      flash[:alert] = I18n.t("profile.settings.notifications.errors.generic");
    end

    redirect_to "/settings"
  end

  def favorites
  end

  def akeys
  end

end
  