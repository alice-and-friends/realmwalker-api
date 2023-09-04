# frozen_string_literal: true

class Api::V1::UsersController < Api::V1::ApiController
  # before_action :set_api_v1_user, only: [:show, :update, :destroy]

  def me
    render json: @current_user, status: :ok
  end

  # GET /api/v1/users
  # def index
  #   @api_v1_users = User.all
  #   render json: @api_v1_users.to_json(:include => [:app_sessions])
  # end

  # GET /api/v1/users/1
  # def show
  #   render json: @api_v1_user
  # end

  # POST /api/v1/users
  # def create
  #   @api_v1_user = User.new(api_v1_user_params)
  #   if @api_v1_user.save
  #     render json: @api_v1_user, status: :created and return
  #   else
  #     render json: @api_v1_user.errors, status: :unprocessable_entity
  #   end
  # end

  # PATCH/PUT /api/v1/users/1
  # def update
  #   if @api_v1_user.update(api_v1_user_params)
  #     render json: @api_v1_user
  #   else
  #     render json: @api_v1_user.errors, status: :unprocessable_entity
  #   end
  # end

  # DELETE /api/v1/users/1
  # def destroy
  #   @api_v1_user.destroy
  # end

  private

  # Use callbacks to share common setup or constraints between actions.
  # def set_api_v1_user
  #   @api_v1_user = User.find(params[:id])
  # end
  #
  # # Only allow a trusted parameter "white list" through.
  # def api_v1_user_params
  #   params.require(:user).permit(:id, :name)
  # end
end
