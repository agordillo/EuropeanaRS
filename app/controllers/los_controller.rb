class LosController < ApplicationController

  before_filter :authenticate_user!, :only => ["like"]

  def show
    @lo = Lo.find_by_id(params[:id])
    return redirect_to(view_context.home_path, :alert => 'Learning Object Not Found') unless @lo
    on_visit(@lo)
    @suggestions = RecommenderSystem.suggestions({:n => 20, :user_profile => current_user_profile, :user_settings => current_user_settings, :lo_profile => @lo.profile})
  end

  def like
    lo = Lo.find_by_id(params[:id])

    errors = []
    errors << 'Learning Object Not Found' unless lo
    errors << 'Like param Not Found' unless params["like"]

    if errors.blank?
      like = (params["like"]==="true")
      if like
        current_user.like(lo)
      else
        current_user.dislike(lo)
      end
    end

    if errors.blank?
      if request.xhr?
        return render :json => {:success => true, :like => current_user.like?(lo)}
      else
        return redirect_to(view_context.home_path, :alert => "Done")
      end
    else
      errors = errors.join(", ");
      if request.xhr?
        return render :json => {:errors => errors}
      else
        return redirect_to(view_context.home_path, :alert => errors)
      end
    end
  end

  private

  def on_visit(lo)
    lo.update_visit_count
    store_lo_profile_in_session(lo.profile) unless user_signed_in?
  end

  def store_lo_profile_in_session(loProfile)
    sessionRecord = Session.getOrCreateUserData(session.id)
    userData = sessionRecord.getUserData

    userData["lo_profiles"] = [] if userData["lo_profiles"].nil?
    loProfileIds = userData["lo_profiles"].map{|loProfile| loProfile["url"]}
    unless loProfileIds.include?(loProfile[:url])
      userData["lo_profiles"] = (userData["lo_profiles"].first(2) << loProfile)
      sessionRecord.updateUserData(userData)
    end
  end

end
  