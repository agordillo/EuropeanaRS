class UsersController < ApplicationController

  before_filter :authenticate_user!

  def show
  end

  def profile
    render "show"
  end

  def edit
    @user = User.find_by_id(params[:id])
    return redirect_to(view_context.home_path, :alert => 'User Not Found') unless @user
  end

  def update
    #Use language as UI language when possible.
    if params["user"] and params["user"]["language"] and params["user"]["ui_language"].blank?
      if Utils.valid_locale?(params["user"]["language"]) and params["user"]["language"] != current_user.ui_language
        params["user"]["ui_language"] = params["user"]["language"]
      end
    end

    if current_user.update_attributes(params.require(:user).permit(:language, :ui_language, :tag_list))
      flash[:notice] = I18n.t("profile.edit.messages.success")
      redirect_to "/profile"
    else
      flash[:alert] = I18n.t("profile.edit.messages.success")
    end
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
    @favorites = current_user.saved_items.first(100)
  end

  def akeys
  end

end
  