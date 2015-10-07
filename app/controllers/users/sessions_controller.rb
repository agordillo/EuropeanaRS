class Users::SessionsController < Devise::SessionsController
# before_filter :configure_sign_in_params, only: [:create]

  before_action :i18n_messages, only: [:new]

  #GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # You can put the params you want to permit in the empty array.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.for(:sign_in) << :attribute
  # end

  private

  def i18n_messages
    #Fix devise bugs
    case flash[:alert]
      when "Invalid email or password."
        flash.now[:alert] = I18n.t("devise.failure.invalid")
    end
  end

end
