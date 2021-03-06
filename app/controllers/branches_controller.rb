class BranchesController < ApplicationController
  before_action :auth_user , :except => [:list]
 layout 'admin'
  authorize_resource :class => false
  def index
    redirect_to :controller => 'restaurants' , :action => 'index'
  end

  def list
    @branches = Branch.where(["restaurant_id = ?",Restaurant.where(["slug = ?",params[:restaurant_slug]]).first.id]).published
    @seating = Array.new
    @branches.each do |b|
      b.restaurant.tables.each do |t|
        @seating << t.seats
        @seating << t.seats - 1 unless t.seats - 1 <= 0
        @seating << t.seats - 2 unless t.seats - 2 <= 0
      end
    end

    render json: {"branches" => @branches, "seating" => @seating.sort.uniq }
  end

  def edit
    
    if current_user.role_id == 1
      @branch = Branch.where(["slug = ?",params[:slug]]).first 
    else
      @branch = Branch.where(["slug = ? AND user_id = ?",params[:slug],current_user.id]).first 
    end
    @branch_count = Branch.count
    if !flash[:model].blank?
        @branch.assign_attributes(flash[:model])
    end
  end

  def new
    
    @branch_count = Branch.count + 1
    @branch = Branch.new
    restaurant = Restaurant.where(["slug = ?",params[:restaurant_slug]]).first
    if !flash[:model].blank?
        @branch.assign_attributes(flash[:model])
    end
  end

  def create
    @branch_count = Branch.count + 1
    @branch = Branch.new(branch_params("test"))
    restaurant = Restaurant.where(["slug = ?",params[:restaurant_slug]]).first
    @branch.restaurant_id = restaurant.id
    @branch.user_id = restaurant.user_id
    if @branch.save
      flash[:notice] = "Details saved"
      redirect_to(:action=>'index')
    else
      flash[:model] = @branch
      flash[:error_model] = @branch.errors.full_messages
     
      redirect_to(:action=>'new')
    end
  end

  def destroy
    if current_user.role_id == 1
      branch = Branch.where(["slug = ?",params[:slug]]).first 
    else
      branch = Branch.where(["slug = ? AND user_id = ?",params[:slug],current_user.id]).first 
    end
    
    if branch.featured_image.blank?
      branch.featured_image = "test"
    end
    directory = File.join("vendor","assets","images","uploads","branches")
    old_path = File.join(directory,branch.featured_image)
    File.delete(old_path) if File.exist?(old_path)
    branch.destroy
    render json: { "gst" => "deleted" }
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
    render json: { "gst" => "deleted" }
  end

  def update
    if current_user.role_id == 1
      @branch = Branch.where(["slug = ?",params[:slug]]).first 
    else
      @branch = Branch.where(["slug = ? AND user_id = ?",params[:slug],current_user.id]).first 
    end
    if @branch.update_attributes(branch_params(@branch.featured_image,@branch.time_zone))
      flash[:notice] = "Details saved"
      redirect_to(:action=>'index')
    else
      flash[:model] = @branch
      flash[:error_model] = @branch.errors.full_messages
      redirect_to(:action=>'edit')
    end
  end

  private
  def branch_params(old_image,zone=nil)
    if old_image.blank?
      old_image = "test"
    end
    Time.zone = params[:branch][:time_zone]
   
    if !params[:branch][:featured_image].blank?
      params[:branch][:featured_image]= upload_files_custom(params[:branch][:featured_image],"branches",old_image)
    end
    params[:branch][:slug] = (params[:restaurant_slug]+" details").parameterize
    date = Time.zone.now - 24*60*60*7
    date = date.strftime("%Y-%m-%d")
    params[:branch][:open] = Time.zone.parse(date + " " +params[:branch][:open])
    params[:branch][:close] = Time.zone.parse(date + " " +params[:branch][:close])
    if params[:branch][:close] < params[:branch][:open]
      params[:branch][:close] = params[:branch][:close] + 24*60*60
    end
    params[:branch][:expiry] = "1";
    params[:branch][:night_club] = "0";
    params[:branch][:seating_capacity] = "1";
    params[:branch][:status] = "1";
    params[:branch][:title] = "";
    params.require(:branch).permit(:night_club,:title,:slug,:status,:address,:email,:position,:phone,:fax,:featured_image,:open,:close,:expiry,:seating_capacity,:time_zone)
  end
  
end
