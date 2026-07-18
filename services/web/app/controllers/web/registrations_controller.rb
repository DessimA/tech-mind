module Web
  class RegistrationsController < ApplicationController
    skip_before_action :authenticate_user!, only: [:new, :create]

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)

      if @user.save
        session[:user_id] = @user.id
        redirect_to conteudos_path, notice: "Conta criada com sucesso!"
      else
        flash.now[:alert] = @user.errors.full_messages.to_sentence
        render :new, status: :unprocessable_content
      end
    end

    private

    def user_params
      params.require(:user).permit(:nome, :email, :password)
    end
  end
end
