class Users::SessionsController < Devise::SessionsController
  
  layout "devise_sessions"
# before_filter :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  def new
    flash[:invalid_user]  = alert 
    redirect_to :root
  end

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
end
