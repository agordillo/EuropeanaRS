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
    if params["user_settings"].blank?
      flash[:alert] = I18n.t("profile.settings.notifications.errors.generic");
    else
      current_user.settings = params["user_settings"]
      current_user.valid?
      if current_user.errors.blank? and current_user.save
        flash[:notice] = I18n.t("profile.settings.notifications.success.generic");
      else
        flash[:alert] =  current_user.errors.full_messages.to_sentence
      end
    end

    redirect_to "/settings"
  end

  def favorites
  end

  def akeys
  end

end
  