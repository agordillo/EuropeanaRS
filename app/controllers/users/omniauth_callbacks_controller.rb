# More info at:
# https://github.com/plataformatec/devise#omniauth

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  # Facebook action method
  def facebook
    #Build user with facebook data
    @user = User.from_omniauth(request.env["omniauth.auth"])
    
    if @user.persisted?
      set_flash_message(:notice, :success, :kind => "Facebook") if is_navigational_format?
      sign_in_and_redirect @user, :event => :authentication
    else
      @user.valid?
      flash[:alert] = @user.errors.full_messages.to_sentence if is_navigational_format?
      session["devise.facebook_data"] = request.env["omniauth.auth"] #Store facebook data in session
      redirect_to new_user_registration_url
    end
  end

  # GET|POST /resource/auth/twitter
  # def passthru
  #   super
  # end

  # GET|POST /users/auth/twitter/callback
  # def failure
  #   super
  # end

  # protected

  # The path used when omniauth fails
  # def after_omniauth_failure_path_for(scope)
  #   super(scope)
  # end
end
