class Admin::UserController < Admin::AdminController
  def index
    @users = User.all
  end

  def show
    @user = User.find_by_id(params[:id])
  end

end
