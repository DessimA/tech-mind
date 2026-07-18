module Web
  class SessionsController < ApplicationController
    skip_before_action :authenticate_user!, only: [:new, :create]

    def new
      redirect_to conteudos_path if logged_in?
    end

    def create
      user = User.find_by(email: params[:email]&.strip&.downcase)

      if user&.authenticate(params[:password])
        session[:user_id] = user.id
        redirect_to conteudos_path, notice: "Login realizado com sucesso!"
      else
        flash.now[:alert] = "Email ou senha inválidos"
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session[:user_id] = nil
      redirect_to login_path, notice: "Logout realizado com sucesso."
    end
  end
end
