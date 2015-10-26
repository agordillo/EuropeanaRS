class AppsController < ApplicationController

  before_filter :authenticate_user!

  def create
    app = App.new(params.require(:app).permit(:name, :app_key, :app_secret))
    app.user_id = current_user.id
    app.save!

    flash[:notice] = I18n.t("profile.api_keys.notifications.success");
    redirect_to "/api_keys"
  end

  def update
    app = App.find(params[:id])
    if app.update_attributes(params.require(:app).permit(:name, :app_key, :app_secret))
      flash[:notice] = I18n.t("profile.apps.notifications.success");
    else
      flash[:alert] = I18n.t("profile.apps.notifications.failure");
    end
    redirect_to "/api_keys"
  end

  def destroy
    app = App.find(params[:id])
    app.destroy
    redirect_to "/api_keys"
  end

end
  