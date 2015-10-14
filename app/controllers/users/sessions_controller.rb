class Users::SessionsController < Devise::SessionsController
# before_filter :configure_sign_in_params, only: [:create]

  before_action :i18n_messages, only: [:new]

  #GET /users/sign_in/europeana
  def new_europeana
    render "new_europeana"
  end

  #POST /users/sign_up/europeana
  def create_europeana
    if params[:public_key].blank? or params[:private_key].blank?
      flash[:alert] = I18n.t("errors.messages.europeana.blank");
      return redirect_to "/users/sign_in/europeana"
    end

    eUserAuth = EuropeanaUserAuth.where(public_key: params[:public_key], private_key: params[:private_key]).first_or_create! do |userAuth|
      userAuth.public_key = params[:public_key]
      userAuth.private_key = params[:private_key]
    end

    @user = eUserAuth.user

    if @user.nil?
      #Create user
      @user = Europeana.createUserWithCredentials(eUserAuth.public_key,eUserAuth.private_key)

      if Europeana.isErrorResponse(@user)
        #On error
        flash[:alert] = I18n.t("devise.omniauth_callbacks.failure", :kind => "Europeana", :reason => @user[:errors])
        return redirect_to "/users/sign_in/europeana"
      end
      
      eUserAuth.user_id = @user.id
      eUserAuth.save!
    end

    #Login user
    flash[:notice] = I18n.t("devise.omniauth_callbacks.success", :kind => "Europeana")
    sign_in_and_redirect @user, :event => :authentication
  end

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
