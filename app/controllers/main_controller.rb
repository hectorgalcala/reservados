class MainController < ApplicationController

   before_action :auth_user, :only => [:reservations]
  @@table
  def index
    @user = User.new
    if !flash[:registration_model].blank?
      @user.name = flash[:registration_model]["name"]
      @user.phone = flash[:registration_model]["phone"]
      @user.email = flash[:registration_model]["email"]
      
    end 
    
    @notice = flash[:notice]

    if !session[:reservation_params].blank? and flash[:delete_session].blank?
      if user_signed_in?
        create_reservation(session[:reservation_params])
        @notice  = @notice + "<br /> Reservation Created"
        session.delete(:reservation_params)
      else 
        # session[:reservation_params] = nil
      end
    end
      @reservation = Reservation.new(:booking=>"7:30 PM")

      @restaurants = Restaurant.published
    
  end
  def register

    flash[:register] = true
    redirect_to :action => :index
  end
  def restaurant
    @user = User.new
    @restaurant = Restaurant.where("slug = ?",params[:slug]).first
    
  end
  def contact_us
    AdminMailer.contact_us(params["message"],params["subject"],params["email"],params["name"]).deliver_now
    flash[:notice]="Your Email has been sent"
    redirect_to root_url
  end
  def get_token

  end
  
  def convert_user
  	AdminMailer.membership_change_request(current_user).deliver_now
    flash[:notice]="You request has been generated !!"
  	redirect_to root_url
  end
  
  
  def reservations
    @user = User.new
    @reservations = Reservation.where("user_id = ? ",current_user.membership)
    
  end
  def customer
    if params[:restaurant].blank? or params[:branch].blank?
      render :json => {"available" => false, "message" => "Please Select a Restaurant"}
    elsif params[:date].blank? or params[:date] == "Fecha"
      render :json => {"available" => false, "message" => "Please Enter a Valid Date"}
    elsif check_date_restriction
      render :json => {"available" => false, "message" => "Reservations are closed for the selected date"}
    elsif params[:time].blank?
      render :json => {"available" => false, "message" => "Please Enter a Valid Time"}
    elsif params[:people].blank?
      render :json => {"available" => false, "message" => "Please Enter Amount of people"}
    else
      Time.zone = params[:time_zone]
      date = params[:date].split('/')
      params[:date] = date[2]+"-"+date[0]+"-"+date[1]
      branch = Branch.find(params[:branch])
      if Time.zone.parse(params[:date]+" "+params[:time]).utc < Time.now.utc
        render :json => {"available" => false, "message" => "Booking Time cannot be in the past"}
      elsif check_times branch
        render :json => {"available" => false, "message" => "Restaurant is closed at the selected time"}
      elsif check_tables  
        render :json => {"available" => false, "message" => "There are no Tables available at the selected time. Please Call on : "+branch.phone+" for further assistance"}
      else
        params[:table_id] = @@table
        session[:reservation_params] = params
        render :json => {"user_signed_in" => user_signed_in? ,"available" => true, "message" => "Creating Resevation", "table" => @@table }
      end
    end
  end
  private 
  def check_tables 
    Time.zone = params[:time_zone]
    booking_time = Time.zone.parse(params[:date]+" "+params[:time]).utc
    tables = Table.reservation_tables_check params[:people].to_i, params[:people].to_i + 2,params[:restaurant]
    return_value = true
    tables.each do |t|
      if !(ReservationTable.where("table_id = ? AND booking = ?",t.id,booking_time).length >= t.quantity)
        return_value = false
        @@table = t.id
        break
      end

    end
    return_value
  end
  private
  def check_date_restriction
    date = params[:date].split('/')
    date = date[2]+"-"+date[0]+"-"+date[1] 
    restrict = DateRestriction.where("restricted_date = ? AND restaurant_id = ?",date , params[:restaurant]).first
    !restrict.blank?
  end
  private
  def check_times branch
    Time.zone = params[:time_zone]
    time = Time.zone.parse(params[:date] + " " + params[:time])
    open_time = Time.zone.parse(params[:date] + " " + branch.open.strftime("%I:%M %p"))
    
    
    if(branch.open.strftime("%d").to_i < branch.close.strftime("%d").to_i)
      close_date = open_time + 24*60*60
    else
      close_date = open_time 
    end
    close_time = Time.zone.parse( close_date.strftime("%Y-%m-%d") + " " + branch.close.strftime("%I:%M %p"))  
    !(time >= open_time && time < close_time )
  end
  private 
  def create_reservation params
    reservation = Reservation.new
    Time.zone = params["time_zone"]
    reservation.people = params["people"]
    reservation.branch_id = params["branch"]
    reservation.status = 1
    reservation.booking = Time.zone.parse(params["date"]+ " " + params["time"])
    reservation.expire_at =reservation.booking + Branch.find(reservation.branch_id).expiry*60*60
    reservation.reservation_code = Digest::SHA1.hexdigest(Time.zone.now.to_s)[0,6]
    reservation.created_by = current_user.id;
    reservation.user_id = current_user.membership
    reservation.reservation_name = current_user.name
    reservation.restaurant_owner = Restaurant.find(params["restaurant"]).user_id;
    reservation.save
    r = Array.new
    (-1...2).each do |i|
      x = ReservationTable.new
      x.table_id = params["table_id"]
      x.booking = reservation.booking + 60*30*i
      x.reservation_id = reservation.id
      x.save
    end
    customer = RestaurantCustomer.where("user_id = ? AND restaurant_owner_id = ?",reservation.created_by , reservation.restaurant_owner)
    if customer.blank?
      customer = RestaurantCustomer.new
      customer.restaurant_owner_id = reservation.restaurant_owner
      customer.user_id = reservation.created_by
      customer.save
    end
    AdminMailer.create_customer_reservation(current_user,reservation.reservation_code,reservation.booking).deliver_now
    AdminMailer.create_restaurant_reservation(User.find(reservation.restaurant_owner), current_user,reservation.reservation_code,reservation.booking).deliver_now
    
  end
  private
  def reservation_params params
    
    
    params.require(:reservation).permit(:reservation_name,:reservation_code,:booking,:expire_at, :people ,:user_id, :status, :branch_id,:created_by,:restaurant_owner)
  end
end
