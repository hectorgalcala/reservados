class BranchesController < ApplicationController
  before_action :authenticate_user!
  layout 'admin'
  authorize_resource :class => false
  def index
    if current_user.role_id == 1
      @branches = Branch.where(["restaurant_id = ?",Restaurant.where(["slug = ?",params[:restaurant_slug]]).first.id]).all
    else 
      @branches = Branch.where(["restaurant_id = ? AND user_id = ?",Restaurant.where(["slug = ?",params[:restaurant_slug]]).first.id,current_user.id]).sorted
    end
  end

  def edit
    if current_user.role_id == 1
      @branch = Branch.where(["slug = ?",params[:slug]]).first 
    else
      @branch = Branch.where(["slug = ? AND user_id = ?",params[:slug],current_user.id]).first 
    end
    
    @branch_count = Branch.count
    
  end

  def new
    @branch_count = Branch.count + 1
    @branch = Branch.new
  end
  
  def create
    @branch_count = Branch.count + 1
    @branch = Branch.new(branch_params("test"))
    restaurant = Restaurant.where(["slug = ?",params[:restaurant_slug]]).first
    @branch.restaurant_id = restaurant.id
    @branch.user_id = restaurant.user_id
    if @branch.save
      flash[:notice] = "Branch saved"
      redirect_to(:action=>'index')
    else
      render("new")
    end

  end

  def destroy
    if current_user.role_id == 1
      @branch = Branch.where(["slug = ?",params[:slug]]).first 
    else
      @branch = Branch.where(["slug = ? AND user_id = ?",params[:slug],current_user.id]).first 
    end
    
    if branch.featured_image.blank?
      branch.featured_image = "test"
    end
    directory = File.join("vendor","assets","images","uploads","branches")
    old_path = File.join(directory,branch.featured_image)
    File.delete(old_path) if File.exist?(old_path)
    branch.destroy
    render json: { "gst": "deleted" } 
  end

  def remove_image
    if current_user.role_id == 1
      @branch = Branch.where(["slug = ?",params[:slug]]).first 
    else
      @branch = Branch.where(["slug = ? AND user_id = ?",params[:slug],current_user.id]).first 
    end
    directory = File.join("vendor","assets","images","uploads","branches")
    old_path = File.join(directory,branch.featured_image)
    File.delete(old_path) if File.exist?(old_path)
    branch.featured_image = ""
    branch.save
    render json: { "gst": "deleted" } 
  end

  def update

    if current_user.role_id == 1
      @branch = Branch.where(["slug = ?",params[:slug]]).first 
    else
      @branch = Branch.where(["slug = ? AND user_id = ?",params[:slug],current_user.id]).first 
    end
    if @branch.update_attributes(branch_params(@branch.featured_image))
      flash[:notice] = "Branch saved"
      redirect_to(:action=>'index')
    else
      @branch_count = Branch.count
      render("edit")
    end
  end

  private
  def branch_params(old_image)
    if old_image.blank?
      old_image = "test"
    end
    if !params[:branch][:featured_image].blank?
      params[:branch][:featured_image]= upload_files_custom(params[:branch][:featured_image],"branches",old_image)
    end
    if params[:branch][:slug].blank?
       params[:branch][:slug] = (params[:branch][:title]+Time.now.to_i.to_s).parameterize
    else
        params[:branch][:slug] = params[:branch][:slug].parameterize
    end
    params.require(:branch).permit(:title,:slug,:status,:address,:email,:position,:phone,:fax,:featured_image)
  end
end
