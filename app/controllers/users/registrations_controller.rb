class Users::RegistrationsController < Devise::RegistrationsController

  # POST /resource
  def create
    build_resource(sign_up_params)

    if resource.has_attribute?(:ui_language)
      resource.ui_language = Utils.valid_locale?(resource.language) ? resource.language : I18n.locale.to_s
      resource.language = resource.ui_language if resource.language.blank?
    end

    resource_saved = resource.save
    yield resource if block_given?
    if resource_saved
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      @validatable = devise_mapping.validatable?
      if @validatable
        @minimum_password_length = resource_class.password_length.min
      end
      respond_with resource
    end
  end

  # GET /resource/edit
  def edit
    unless resource.ug_password_flag
      # In Devise, when the user password is changed, the session is lost.
      # We have to sign in the user again
      user = current_user #get current user before making changes
      @raw_password = Devise.friendly_token[0,8]
      resource.password = @raw_password
      resource.save!
      sign_in(user, :bypass=>true)
    end
    render :edit
  end

  # PUT /resource
  # We need to use a copy of the resource because we don't want to change
  # the current user in place.
  def update
    generated_password = resource.encrypted_password unless resource.ug_password_flag

    super do |user|
      if user.errors.blank?
        userNeedsSaving = false

        #Change password flag when the user specifies a password
        if !user.ug_password_flag and user.encrypted_password != generated_password
          user.ug_password_flag = true
          userNeedsSaving = true
        end

        #Use language as UI language when possible.
        if Utils.valid_locale?(user.language) and user.language != user.ui_language
          user.ui_language = user.language
          userNeedsSaving = true
        end

        user.save! if userNeedsSaving
      else
        @raw_password = params["user"]["current_password"] unless (resource.ug_password_flag or params["user"].blank?)
      end
    end
  end


  protected

  def after_sign_up_path_for(resource)
    view_context.home_path
  end


  private

  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :ui_language, :language, :tag_list)
  end

  def account_update_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :current_password, :ui_language, :language, :settings, :tag_list)
  end
  
end


# class Devise::RegistrationsController < DeviseController
#   prepend_before_filter :require_no_authentication, only: [ :new, :create, :cancel ]
#   prepend_before_filter :authenticate_scope!, only: [:edit, :update, :destroy]

#   # GET /resource/sign_up
#   def new
#     build_resource({})
#     @validatable = devise_mapping.validatable?
#     if @validatable
#       @minimum_password_length = resource_class.password_length.min
#     end
#     respond_with self.resource
#   end

#   # POST /resource
#   def create
#     build_resource(sign_up_params)

#     resource_saved = resource.save
#     yield resource if block_given?
#     if resource_saved
#       if resource.active_for_authentication?
#         set_flash_message :notice, :signed_up if is_flashing_format?
#         sign_up(resource_name, resource)
#         respond_with resource, location: after_sign_up_path_for(resource)
#       else
#         set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
#         expire_data_after_sign_in!
#         respond_with resource, location: after_inactive_sign_up_path_for(resource)
#       end
#     else
#       clean_up_passwords resource
#       @validatable = devise_mapping.validatable?
#       if @validatable
#         @minimum_password_length = resource_class.password_length.min
#       end
#       respond_with resource
#     end
#   end

#   # GET /resource/edit
#   def edit
#     render :edit
#   end

#   # PUT /resource
#   # We need to use a copy of the resource because we don't want to change
#   # the current user in place.
#   def update
#     self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
#     prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

#     resource_updated = update_resource(resource, account_update_params)
#     yield resource if block_given?
#     if resource_updated
#       if is_flashing_format?
#         flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ?
#           :update_needs_confirmation : :updated
#         set_flash_message :notice, flash_key
#       end
#       sign_in resource_name, resource, bypass: true
#       respond_with resource, location: after_update_path_for(resource)
#     else
#       clean_up_passwords resource
#       respond_with resource
#     end
#   end

#   # DELETE /resource
#   def destroy
#     resource.destroy
#     Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
#     set_flash_message :notice, :destroyed if is_flashing_format?
#     yield resource if block_given?
#     respond_with_navigational(resource){ redirect_to after_sign_out_path_for(resource_name) }
#   end

#   # GET /resource/cancel
#   # Forces the session data which is usually expired after sign
#   # in to be expired now. This is useful if the user wants to
#   # cancel oauth signing in/up in the middle of the process,
#   # removing all OAuth session data.
#   def cancel
#     expire_data_after_sign_in!
#     redirect_to new_registration_path(resource_name)
#   end

#   protected

#   def update_needs_confirmation?(resource, previous)
#     resource.respond_to?(:pending_reconfirmation?) &&
#       resource.pending_reconfirmation? &&
#       previous != resource.unconfirmed_email
#   end

#   # By default we want to require a password checks on update.
#   # You can overwrite this method in your own RegistrationsController.
#   def update_resource(resource, params)
#     resource.update_with_password(params)
#   end

#   # Build a devise resource passing in the session. Useful to move
#   # temporary session data to the newly created user.
#   def build_resource(hash=nil)
#     self.resource = resource_class.new_with_session(hash || {}, session)
#   end

#   # Signs in a user on sign up. You can overwrite this method in your own
#   # RegistrationsController.
#   def sign_up(resource_name, resource)
#     sign_in(resource_name, resource)
#   end

#   # The path used after sign up. You need to overwrite this method
#   # in your own RegistrationsController.
#   def after_sign_up_path_for(resource)
#     after_sign_in_path_for(resource)
#   end

#   # The path used after sign up for inactive accounts. You need to overwrite
#   # this method in your own RegistrationsController.
#   def after_inactive_sign_up_path_for(resource)
#     scope = Devise::Mapping.find_scope!(resource)
#     router_name = Devise.mappings[scope].router_name
#     context = router_name ? send(router_name) : self
#     context.respond_to?(:root_path) ? context.root_path : "/"
#   end

#   # The default url to be used after updating a resource. You need to overwrite
#   # this method in your own RegistrationsController.
#   def after_update_path_for(resource)
#     signed_in_root_path(resource)
#   end

#   # Authenticates the current scope and gets the current resource from the session.
#   def authenticate_scope!
#     send(:"authenticate_#{resource_name}!", force: true)
#     self.resource = send(:"current_#{resource_name}")
#   end

#   def sign_up_params
#     devise_parameter_sanitizer.sanitize(:sign_up)
#   end

#   def account_update_params
#     devise_parameter_sanitizer.sanitize(:account_update)
#   end
# end