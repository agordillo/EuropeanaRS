class LosController < ApplicationController

  before_filter :authenticate_user!, :only => ["like"]

  def show
    @lo = Lo.find_by_id(params[:id])
    return redirect_to(view_context.home_path, :alert => 'Learning Object Not Found') unless @lo
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
        current_user.unlike(lo)
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

end
  