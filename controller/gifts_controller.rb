class GiftsController < ApplicationController
  
require 'mechanize'
require 'pdf/writer'
require 'pdf/simpletable'
layout "shopping"
before_filter :button_adv, :only => [:index,:category,:merchant,:search]
before_filter :ladder_adv, :only => [:index,:category,:merchant,:search]
before_filter :small_ladder_adv,:only=>[:index,:category,:merchant,:search]
before_filter :find_text_ads, :only => [:index,:category,:merchant]
before_filter :square_adv, :only => [:index,:category,:merchant,:product,:user_review,:search]
before_filter :small_square_adv,:only=>[:index,:category,:merchant,:search]
before_filter :find_text_ads, :only => [:index,:category,:merchant,:search]

#------- Modified code --------------------------------

 def index
    session[:label] = "index"  
    get_seo_info
    @account = getaccount_info    
    @cart = session[:cart]
    conditions = ["status = 1"]
    #~ render :text => myarr[0] and return
    @total_products_count = Product.find(:all,:conditions => conditions)
    #~ session[:sort] = "id DESC" if session[:sort] == nil
    session[:sort] = :random 
    session[:sort] = 'price' if params[:sort] == "lprice"
    session[:sort] = 'id DESC' if params[:sort] == "latest"
    session[:sort] = 'price DESC' if params[:sort] == "hprice"
    session[:sort] = 'title' if params[:sort] == "title"    
    @products = Product.paginate(:order=> session[:sort], 
      :per_page => 10, 
      :page=>params[:page],
      :conditions => ["id != ? AND status = 1", 0])    
    @current_page_number = params[:page]
    @current_page_number = 1 if @current_page_number.blank?
   @final_ads =$ads.size
  end

def product
  
    session[:label] = ""
    session[:product_layout] = "def" if session[:product_layout].blank?    
    session[:product_layout] = "classic" if params[:layout] == "classic"
    session[:product_layout] = "def" if params[:layout] == "def"
    
    @product = Product.find_by_perma_link(params[:id])
    if !@product.blank?      
      
        session[:last_product_id_viewed] = @product.id
         @shoppingseocontent=Seo.find(:first,:select=>"title,description,keywords",:conditions=>["pagename LIKE ?","Shopping Home"])
      if !@shoppingseocontent.blank?
         @pagetitle= @product.title + " from #{@product.merchant.name}. Send this Gift to Kakinada" 
         if @product.details.blank?
            @pagedescription=(@shoppingseocontent.description).gsub(/(<[^>]*>)|\n|\t|\&nbsp;|/s, "").slice(0,300)  if !@shoppingseocontent.description.blank? 
         else
           @pagedescription=(@product.details).gsub(/(<[^>]*>)|\n|\t|\&nbsp;|/s, "").slice(0,80)  if !@product.details.blank? 
          end

          if @product.keywords.blank?
          @keywords=@shoppingseocontent.keywords.split(',')   if !@shoppingseocontent.keywords.blank?
          else
          @keywords= @product.keywords.split(',') if !@product.keywords.blank? 
         
          end
          
      if(@keywords.size > 12) 
      @arr=Array.new
       for i in 0...12
         @arr << @keywords[i]
        end 
      @arr=@arr.join(',')
      else
      @pagekeywords=@shoppingseocontent.keywords  
      end
     end
        @account = getaccount_info    
        @product.update_attribute("views", @product.views + 1)

   similar_products(@product)
   featured_product(@product)
   ordered_items(@product)

   if params[:featureproduct_page]
    respond_to do |format|
    #format.html  
    format.js {
      render :update do |page|
         page.replace_html 'featured', :partial => 'product_featured' 
      end
}
 end
 
end


  if params[:similar_products_page]
    respond_to do |format|
    #format.html 
    format.js {
      render :update do |page|
        page.replace_html 'related', :partial => 'related_products' 
      end 
  }
  end
  end
else
redirect_to :action => :index
end

  end


 #---------------- end of modified code -----------------------

def confirmation
@account = getAccount()
 find_order = Order.find(:first,:conditions => ["id = #{ params[:Order_Id]}"])
paystatus = PaymentStatus.new
paystatus.time_created = Time.now
paystatus.customer_id = find_order.customer_id
paystatus.order_id = params[:Order_Id]
if paystatus.save
   session[:order_id] = nil
   session[:guest_user_id] = nil
   @find_order = Order.find(:first,:conditions => ["id = #{ params[:Order_Id]}"])
   session[:order_review_id] = @find_order.id 
   if params[:some] == 'Y'
   @cart = session[:cart]
  @featureproduct_pages, @featureproduct = paginate :products, :per_page => 3,:conditions => ["featured = ?", 1], :order=>'id desc'
   @mer_emails_arr = session[:merchant_mails]
   @mer_mobile_arr = session[:merchant_mobiles]
   
     shippingmails = Shop.find(:all)
    if  !shippingmails.blank?
     for s in shippingmails
              items = Orderitem.find(:all,:conditions => ["order_id = #{@find_order.id}"])
              @products_list = []
              for item in items
                  @products_list << item
              end
     end
   end

          if !@mer_emails_arr.blank?
              #send email to merchant
            @mer_emails_arr.each do |email| 
              merchant = Merchant.find(:first,:conditions => ["email LIKE ?",email]) 
                   #~ render :text=>merchant.id and return
              items = Orderitem.find(:all,:conditions => ["order_id = #{@find_order.id}"])
            end
          end
       
  flash[:notice] = "Order has been placed!"
   session[:cart]=nil
  session[:pay_confirm] = 'from_confirm'
  
  ##### order_has_been_placed method code
     session[:pay_confirm] = ""
     session[:label] = ""
    @pagetitle = "Congratulations, your order is processed"
   @pagedescription="The best way to shop and send gifts to Kakinada."
   @pagekeywords= "sends gifts to kakianda, gifts shop, online shopping, flowers & cakes, beautiful gifts"
    #~ @account = getAccount()
    #
    #session[:cart].clear
    session[:freight_cost] = 0.0
    session[:freight_suggests] = "None."
    
    render(:file => "#{RAILS_ROOT}/app/views/templates/#{Shop.def_template_name}/frontend/order_has_been_placed.html.erb", 
      :layout => true)

  else
   @pagetitle = "Sorry, your order is not processed"
   @pagedescription="The best way to shop and send gifts to Kakinada."
   @pagekeywords= "sends gifts to kakianda, gifts shop, online shopping, flowers & cakes, beautiful gifts"
   @featureproduct_pages, @featureproduct = paginate :products, :per_page => 3,:conditions => ["featured = ?", 1], :order=>'id desc'
   @pagetitle = "Sorry, your order is not processed"
   @pagedescription="The best way to shop and send gifts to Kakinada."
   @pagekeywords= "sends gifts to kakianda, gifts shop, online shopping, flowers & cakes, beautiful gifts"
     @featureproduct_pages, @featureproduct = paginate :products, :per_page => 3,:conditions => ["featured = ?", 1], :order=>'id desc'
   @total_amount = session[:total]
   
   @new_order = Order.create(:time_created =>Time.now,	:customer_id =>@find_order.customer_id,:from_name=>@find_order.from_name,:from_email=>@find_order.from_email,:from_phone=>@find_order.from_phone,
   :from_zipcode=>@find_order.from_zipcode,:from_street=>@find_order.from_street ,:from_country=>@find_order.from_country,:from_state=>@find_order.from_state,
  :from_city=>@find_order.from_city,	:to_steet=>@find_order.to_steet,:to_zipcode=>@find_order.to_zipcode,:to_country=>@find_order.to_country,	:to_state	=>@find_order.to_state,:to_city=>@find_order.to_city,:to_phone_no=>@find_order.to_phone_no,	
  :to_delivery_date=>@find_order.to_delivery_date,:to_name_user=>@find_order.to_name_user,:note=>@find_order.note,:status=>@find_order.status,
   :order_browser=> @find_order.order_browser ,:order_ipaddress=> @find_order.order_ipaddress)
   items = Orderitem.find(:all,:conditions => ["order_id = #{@find_order.id}"])
  
   if items
        for item in items
          item.update_attributes(:order_id => @new_order.id )
        end
  end
      
  payment_status = PaymentStatus.find_by_order_id(@find_order.id)
  payment_status.destroy if !payment_status.blank?
  
  Order.find(@find_order.id).destroy if !@find_order.blank?
  
  @find_order = @new_order

render(:file => "#{RAILS_ROOT}/app/views/templates/#{Shop.def_template_name}/frontend/#{action_name}.html.erb", 
:layout => true)  
   end
   
 end
 

 else
   redirect_to :action => :index 
  end
end

  
  
def myorders
    session[:label] = "my-acct"
    @pagetitle = "My Orders"
    @account = getAccount()
     @cart = session[:cart]
     if @account.blank?
      flash[:notice] = "Please login."
      redirect_to :controller =>"home",:action => "login",:url=>request.request_uri 
    else
      @order_latest=Order.find(:first,:conditions => ["orders.customer_id like ? AND (payment_statuses.authdesc = 'Y')", @account.id],:order => "orders.time_created DESC",:include => ["payment_status"]) 
      
      
     if @order_latest   
       @orders = Order.paginate(:per_page => 5,:page=>params[:page],:conditions => ["(orders.customer_id like ? ) AND (payment_statuses.authdesc = 'Y')", @account.id], :order=>'orders.time_created DESC',:include => ["payment_status"])
   end
 
 if params[:per_page] == 'Ordered date' && @order_latest
    @orders=Order.paginate(:per_page => 5,:page=>params[:page],:conditions => ["(orders.customer_id like ? ) AND (payment_statuses.authdesc = 'Y')", @account.id ],:order => "orders.time_created DESC",:include => ["payment_status"])
  elsif params[:per_page] == 'Delivery date' && @order_latest
     
   @orders=Order.paginate(:per_page => 5,:page=>params[:page],:conditions => ["(orders.customer_id like ? ) AND (payment_statuses.authdesc = 'Y')", @account.id],:order => "orders.to_delivery_date DESC",:include => ["payment_status"])    
else
  if @order_latest
 
    @orders =Order.paginate(:per_page => 5,:page=>params[:page],:conditions => ["(orders.customer_id like ?) AND (payment_statuses.authdesc = 'Y')", @account.id],:order => "orders.time_created DESC",:include => ["payment_status"])
end
end
 
     #render :text => @orders and return
       render(:file => "#{RAILS_ROOT}/app/views/templates/#{Shop.def_template_name}/frontend/#{action_name}.html.erb", 
     :layout => true)
    end
    
  end
  

  
 
  def search
    
    @account = getAccount()
    @cart = session[:cart]
    
    session[:sort] = "id DESC" if session[:sort] == nil
    session[:sort] = 'price' if params[:sort] == "lprice"
    session[:sort] = 'id DESC' if params[:sort] == "latest"
    session[:sort] = 'price DESC' if params[:sort] == "hprice"
    session[:sort] = 'title' if params[:sort] == "title"
    
    # request from search form
    if request.post?
      params[:darken] = false
      session[:label] = ""

      @pagetitle = "Search"
      if params[:search][:query].blank?
    
        redirect_to :action=>'index', :controller =>"gifts"
      else
 
        query = params[:search][:query] || params[:search_text]

        ##########
        q = query
        q = query.gsub(/\s/, ' , ')
        @query_search = q
        q = "%"+q+"%"

            
        @products = Product.paginate(:order=> session[:sort], 
          :per_page => 10, 
          :page=>params[:page],
          :conditions => ["title like ? OR details like ? OR labels like ? AND status=1", q,q,q])
        ##########
         @current_page_number = params[:page]
        @current_page_number = 1 if @current_page_number.blank?
        @total_products = Product.find(:all,:conditions => ["title like ? OR details like ? OR labels like ? AND status=1", q,q,q])
        @header = "Gift(s) for your query: '" + query + "'"
        #~ render :text => @products.size and return
        render(:file => "#{RAILS_ROOT}/app/views/templates/#{Shop.def_template_name}/frontend/#{action_name}.html.erb", 
          :layout => true)
      end    
    end
    
    
    # request from menu
    if request.get?
      
      params[:darken] = true
      if params[:label].blank?
        @pagetitle = session[:label].to_s
        query = session[:label].to_s || params[:search_text]
    #session[:label] = query
      else
        @pagetitle = params[:label].to_s
        query = params[:label].to_s || params[:search_text]
        session[:label] = query 
      
      end    
       query = params[:search_text] if !params[:search_text].blank?
       q = query
       @query_search = q
       q = "%"+q+"%"
      q = q.downcase
      @products = Product.paginate(:order=> session[:sort], 
        :per_page => 10, 
        :page=>params[:page],
        :conditions =>  ["title like ? OR details like ? OR labels like ? AND status=1", q,q,q]) 
      @header = "" + query + ""
            @current_page_number = params[:page]
        @current_page_number = 1 if @current_page_number.blank?
        @total_products = Product.find(:all,:conditions => ["title like ? OR details like ? OR labels like ? AND status=1", q,q,q])
      #~ render :text => @products.size and return
      render(:file => "#{RAILS_ROOT}/app/views/templates/#{Shop.def_template_name}/frontend/#{action_name}.html.erb", 
        :layout => true)
    end  
    
  end
    
  
  
  def order_has_been_placed
    
   session[:merchant_mails] =""
    session[:merchant_mobiles]=""
      session[:pay_confirm] = ""
     session[:label] = ""
  @pagetitle = "Congratulations, your order is processed"
   @pagedescription="The best way to shop and send gifts to Kakinada."
   @pagekeywords= "sends gifts to kakianda, gifts shop, online shopping, flowers & cakes, beautiful gifts"
    @account = getAccount()
   @featureproduct_pages, @featureproduct = paginate :products, :per_page => 3,:conditions => ["featured = ?", 1], :order=>'id desc'
    session[:freight_cost] = 0.0
    session[:freight_suggests] = "None."
    
    render(:file => "#{RAILS_ROOT}/app/views/templates/#{Shop.def_template_name}/frontend/#{action_name}.html.erb", 
      :layout => true)

  end  
    
  
  
  
  def category
    begin
      session[:label] = ""
      @account = getAccount()
      @cart = session[:cart]
      session[:sort] = "id DESC" if session[:sort] == nil
      session[:sort] = 'price' if params[:sort] == "lprice"
      session[:sort] = 'id DESC' if params[:sort] == "latest"
      session[:sort] = 'price DESC' if params[:sort] == "hprice"
      session[:sort] = 'title' if params[:sort] == "title"

if !params[:cat].blank?
      main_category = ShoppingCategory.find(:first, :conditions => ["perma_link LIKE ? ",params[:cat]])
       @category = ShoppingCategory.find(:first, :conditions => ["perma_link LIKE ? AND p_id LIKE ?","%#{params[:id]}%",main_category.id])
  else
       @category = ShoppingCategory.find(:first, :conditions => ["perma_link LIKE ? ",params[:id]])

  end 
      session[:shopping_category_id] = @category.id
            @pagetitle= @category.page_title
         @pagedescription=(@category.description).gsub(/(<[^>]*>)|\n|\t|\&nbsp;|/s, "").slice(0,300)  if !@category.description.blank? 
         @keywords=@category.keywords.split(',')   if !@category.keywords.blank?
    if !@keywords.blank?
      if(@keywords.size > 12) 
      @arr=Array.new
       for i in 0...12
         @arr << @keywords[i]
        end 
      @arr=@arr.join(',')
      else
      @pagekeywords=@category.keywords  
      end
     end
        @myarr = []
        category_list= ProductCategory.find(:all, :conditions=>["shopping_category_id = ? ", @category.id])
     for cat in category_list
          @myarr << cat.product_id 
        end
        
      if !@myarr.blank?
        @products = Product.paginate(:order=> session[:sort], 
        :per_page => 10,
        :conditions=>["id in (#{@myarr.join(',')}) AND status=1"],:page=>params[:page])
        
        @current_page_number = params[:page]
        @current_page_number = 1 if @current_page_number.blank?
        
        @total_products = Product.find(:all,:conditions => ["id in (#{@myarr.join(',')}) AND status=1"])
        else
        @products = Product.paginate(:order=> session[:sort], :per_page => 10,:conditions=>["shopping_category_id = ? AND status=1 ", @category.id],:page=>params[:page])
        @current_page_number = params[:page]
        @current_page_number = 1 if @current_page_number.blank?
        @total_products = Product.find(:all,:conditions => ["shopping_category_id = ? AND status=1", @category.id])
end   
    

      render(:file => "#{RAILS_ROOT}/app/views/templates/#{Shop.def_template_name}/frontend/#{action_name}.html.erb", 
        :layout => true)
     rescue 
         redirect_to :action=>'index', :controller =>"gifts"
    end     
  end  
   
  def merchant
        begin 
     @account = getAccount()
     @cart = session[:cart]
      session[:sort] = "id DESC" if session[:sort] == nil
      session[:sort] = 'price' if params[:sort] == "lprice"
      session[:sort] = 'id DESC' if params[:sort] == "latest"
      session[:sort] = 'price DESC' if params[:sort] == "hprice"
      session[:sort] = 'title' if params[:sort] == "title"
    
      @merchant = Merchant.find_by_perma_link(params[:id])
     if !@merchant.blank? 
       session[:merchant_id] = @merchant.id
   
      @pagetitle = "Inkakinada Shopping Retailer - " + @merchant.name
      @shoppingseocontent=Seo.find(:first,:select=>"title,description,keywords",:conditions=>["pagename LIKE ?","Shopping Merchant"])

     if !@shoppingseocontent.blank?
     if !@shoppingseocontent.title.blank? 
     @pagetitle= @shoppingseocontent.title
     end
    
      if !@shoppingseocontent.description.blank? 
      @pagedescription=(@shoppingseocontent.description).gsub(/(<[^>]*>)|\n|\t|\&nbsp;|/s, "").slice(0,300)
      end
     
     
      if(!@shoppingseocontent.keywords.blank? ) 
      @keywords=@shoppingseocontent.keywords.split(',') 
      if(@keywords.size > 12) 
      @arr=Array.new
      for i in 0...12
       @arr << @keywords[i]
     end 
      @arr=@arr.join(',')
      else
      @pagekeywords=@shoppingseocontent.keywords  
      end
     end
    end
    
      @products = Product.paginate(:order=> session[:sort], 
        :per_page => 10,
        :conditions=>["merchant_id = ? ", @merchant.id], :page=>params[:page])
        
else
render(:file => "#{RAILS_ROOT}/app/views/templates/#{Shop.def_template_name}/frontend/#{action_name}.html.erb", :layout => true)


end
                              
render(:file => "#{RAILS_ROOT}/app/views/templates/#{Shop.def_template_name}/frontend/#{action_name}.html.erb", :layout => true)
       
       rescue 
         redirect_to :action=>'index', :controller =>"gifts"
    end  
   
   
   end  
  

    
 def login
    @pagetitle = "User Login"
    session[:label] = "login"
    if request.get?
      @pagetitle = "Login"
      
      session[:user_id] = nil
      # session[:cart] = nil
      session[:account_type] = nil
      @account = nil
      
      render(:file => "#{RAILS_ROOT}/app/views/templates/#{Shop.def_template_name}/frontend/#{action_name}.html.erb", 
        :layout => true)
      
    else
      @account = Account.new(params[:account])
      logged_in_account = @account.try_to_login
      if logged_in_account
        if logged_in_account.suspended != 1
          session[:user_id] = logged_in_account.id

          session[:cart] = SessionCart.new(logged_in_account) if session[:cart].nil?
          
          if session[:should_remember_product_id]
            redirect_to(:action => "product", :controller =>"gifts", :id=>session[:last_product_id_viewed])
          else
            redirect_to(:action => "index", :controller =>"gifts")
          end
          
        else
          flash[:notice] = "Your account is not actived."
          redirect_to(:action => "login", :controller =>"gifts")
        end  
      else
        flash[:notice] = "Invalid user/password combination."
        redirect_to(:action => "login", :controller =>"gifts")
      end
    end
  end
  
  # This actually is a 'No Render action'
  def logout
    @pagetitle = "Logged Out"
    session[:user_id] = nil
    session[:should_remember_product_id] = false
    
    flash[:notice] = "Logged out."
    redirect_to :action=>'login', :controller =>"gifts"
  end


def send_gift
  begin
    @pagetitle = "Your cart"   
    @account = getAccount()
    @gift = session[:cart]


     #~ if request.post?
      product= Product.find_by_perma_link(params[:id])
      account = getAccount()
      quantity = 0
      #~ variant_value =0   #0
      
       if params[:variantlist].blank?
         variant_value=product.price 
        else
         variant_value = params[:variantlist].to_f  
        end
        
        if params[:quantity].blank?
         quantity=1
        else
         quantity = params[:quantity].to_i  
        end

      session[:cart] = SessionCart.new(account) if session[:cart].nil?
      session[:cart].add_product(product.id,variant_value)

    if quantity >= 2 and quantity <= 50
        for i in 1..quantity-1
          session[:cart].add_product(product.id,variant_value)
        end  
      end  
  
   @myitems =  session[:cart].items
    for item in @myitems
     if item.product_id == product.id
       
         item.add_variant(variant_value.to_f)

     end
   end
     
     redirect_to :action => 'gift_page'
       rescue 
         redirect_to :action=>'index', :controller =>"gifts"
    end  
end

def update_options
  

   @product = Product.find(params[:id])
   @p = params[:change_to].to_f

myitems =  session[:cart].items
    for item in myitems
     if item.product_id == @product.id
       item.increase_quantity(1)
        item.add_variant(@p)
        @q = item.quantity
     end
   end
end



 def grand_update   
   @account = getAccount()
   @product = Product.find(params[:id])
   @p = params[:change_qty_to].to_i
   myitems =  session[:cart].items
    for item in myitems
     if item.product_id == @product.id
        item.increase_quantity(@p)
     end
   end
end

 
def gift_page

    if session[:for_ie] 
         session[:gift_url] = 'gift_login'
    else
      session[:gift_url] = nil
     end

   @pagetitle= "Your Gifts Box. Manage your Gifts."
         @pagedescription="Manage your gifts you are planning to send Kakinada. The best way to shop gifts."
         @pagekeywords= "sends gifts to kakianda, gifts shop, online shopping, flowers & cakes, beautiful gifts"
    if session[:cart] == nil
    flash[:notice]= "Please select your gift"
    redirect_to :action=>'index' and return
  end
  @phoneaddress = UserPhoneBook.new
  
  if !session[:user_id].blank?  
    @user =  User.find_by_id(session[:user_id])
    @addresses = UserPhoneBook.find(:all,:conditions => ["user_id LIKE ?",session[:user_id] ])
   @add_first =  UserPhoneBook.find(:first,:conditions => ["default_address = 1 AND user_id LIKE ?",session[:user_id] ])
 end

  @gift = session[:cart]
session[:for_ie] = nil

  @my_total = 0 
 
for gift in @gift.items
 p = Product.find(gift.product_id) 
 unit_price = p.price    
if p.variant_status == '1' 
 unit_price = p.price
 end 
  final_price = unit_price * gift.quantity 
  @my_total += final_price 

     
end

end

   def show_address

       @user =  User.find_by_id(session[:user_id])
       @recepient = params[:id]
     if !params[:id].blank?   
             @addresses = UserPhoneBook.find_by_title(params[:id])
          end  
          @list_of_addresses = UserPhoneBook.find(:all,:conditions => ["user_id LIKE ?",session[:user_id] ])
        render :partial=> 'show_address'   
  end

def update_address
   @phoneaddress = UserPhoneBook.new
             @addresses = UserPhoneBook.find(:all,:conditions => ["user_id LIKE ?",session[:user_id] ])
             @add_first =  UserPhoneBook.find(:first,:conditions => ["default_address = 1 AND user_id LIKE ?",session[:user_id] ])

        render :partial=> 'update_address'   
  end



def delete_gift   

          product = Product.find(params[:id])
          session[:cart].delete_product(product.id)
          @gift= session[:cart]
           flash[:notice] = "Gift has been removed from cart."      
          render :partial => 'delete_gift'and return

  
end
 
  def show_success
    session[:guest] =nil
   if request.post?
  
      if !params[:id].blank?
      @user = User.find(params[:id])
      else
        @user = User.find(session[:guest_user_id])
      end
       @phoneaddress = UserPhoneBook.new
    
       if !params[:orders][:to_name_user].blank? && params[:addresslist] == 'on'
                     params[:phoneaddress][:title] = params[:orders][:to_name_user] 
                   user_title = UserPhoneBook.find_by_title(params[:orders][:to_name_user])
                     if user_title.blank?
                        @phoneaddress.title= params[:phoneaddress][:title]
                        @phoneaddress.address= params[:phoneaddress][:address]
                          @phoneaddress.zipcode= params[:phoneaddress][:zipcode]
                         @phoneaddress.phone= params[:phoneaddress][:phone]
                        @phoneaddress.country= params[:to_country][:country]
                @phoneaddress.state= params[:phoneaddress][:state]
                @phoneaddress.city= params[:phoneaddress][:city]
                         @phoneaddress.default_address= 0
                         @phoneaddress.user_id=@user.id
                         if !params[:orders][:to_name_user].blank?
                         @phoneaddress.to_user_name = params[:orders][:to_name_user] 
                         else
                             @phoneaddress.to_user_name =  @phoneaddress.title
                         end
                         @phoneaddress.save!
                         #~ flash[:notice] = "Address was successfully created."
                       session[:user_address_to] = {:address => @phoneaddress.address,:delivery_date => params[:delivery][:date],:phone => @phoneaddress.phone,:title => @phoneaddress.title,:note=>params[:orders][:note] ,:to_name_user=>params[:orders][:to_name_user],
:country=>  @phoneaddress.country.blank? ? params[:to_country][:country] : @phoneaddress.country, :state=> @phoneaddress.state.blank? ? params[:phoneaddress][:state] : @phoneaddress.state, :city=>@phoneaddress.city.blank? ? params[:phoneaddress][:city] : @phoneaddress.city,
:zipcode=>  @phoneaddress.zipcode.blank? ? params[:phoneaddress][:zipcode] : @phoneaddress.zipcode }
                      order_items_list
                     else      
               
                     session[:user_address_to] = {:address => user_title.address,:delivery_date => params[:delivery][:date],:phone => user_title.phone,:title => user_title.title,:note=>params[:orders][:note] ,:to_name_user=>params[:orders][:to_name_user],
:country=>@phoneaddress.country.blank? ? params[:to_country][:country] : @phoneaddress.country, :state=> @phoneaddress.state.blank? ? params[:phoneaddress][:state] : @phoneaddress.state, :city=> @phoneaddress.city.blank? ? params[:phoneaddress][:city] : @phoneaddress.city,
:zipcode=>  @phoneaddress.zipcode.blank? ? params[:phoneaddress][:zipcode] : @phoneaddress.zipcode}
                      order_items_list
                     end
           #~ end
        else
          
                     @phoneaddress.title= params[:phoneaddress][:title]
                        @phoneaddress.address= params[:phoneaddress][:address]
                          @phoneaddress.zipcode= params[:phoneaddress][:zipcode]
                         @phoneaddress.phone= params[:phoneaddress][:phone]
                        @phoneaddress.country= params[:to_country][:country]
                @phoneaddress.state= params[:phoneaddress][:state]
                @phoneaddress.city= params[:phoneaddress][:city]
                         @phoneaddress.default_address= 0
                         @phoneaddress.user_id=@user.id
                         if !params[:orders][:to_name_user].blank?
                         @phoneaddress.to_user_name = params[:orders][:to_name_user] 
                         else
                             @phoneaddress.to_user_name =  @phoneaddress.title
                         end

                user_title = UserPhoneBook.find_by_title(params[:orders][:to_name_user])
                                session[:user_address_to] = {:address => @phoneaddress.address,:delivery_date => params[:delivery][:date],:phone => @phoneaddress.phone,:title => @phoneaddress.title,:note=>params[:orders][:note] ,:to_name_user=> @phoneaddress.to_user_name ,
:country=>  @phoneaddress.country.blank? ? params[:to_country][:country] : @phoneaddress.country, :state=> @phoneaddress.state.blank? ? params[:phoneaddress][:state] : @phoneaddress.state, :city=>@phoneaddress.city.blank? ? params[:phoneaddress][:city] : @phoneaddress.city,
:zipcode=>  @phoneaddress.zipcode.blank? ? params[:phoneaddress][:zipcode] : @phoneaddress.zipcode }

         order_items_list
       end
        #~ order_items_list
        render :partial => "show_success" and return
 
  end
end
  
    def step1_sucess
       session[:gift_url] = nil
      @phoneaddress = UserPhoneBook.new

     session[:user_address_from] ={:from_name => params[:orderfrom_name],:from_email => params[:orderfrom_email],
       :from_phone =>params[:from_phone],:from_street =>params[:from_street],:from_zipcode=>params[:from_zipcode],
       :from_country=>params[:mycountry] ,:from_state=>params[:from_state],:from_city=>params[:from_city] }

           if session[:user_id].blank? && session[:guest_user_id].blank?
              user = User.create(:name =>params[:orderfrom_name],:email => params[:orderfrom_email],:password => 'inkakinada' ,:mobile_number =>params[:from_phone],
              :address=>params[:from_street],:role_id => 7,:country=>params[:mycountry],:city=>params[:from_city],
              :state=>params[:from_state],:zipcode =>params[:from_zipcode] )
              #~ session[:user_id] = user.id
              if user.save
              #~ session[:user_id]=user.id
              session[:guest_user_id] = user.id
              @user = user
             else
               flash[:notice] ="user already exist"
               redirect_to :action => :gift_page and return
              end
              elsif !session[:guest_user_id].blank?
                  @user = User.find(session[:guest_user_id])
              else
                     user = User.find(session[:user_id])
                     @user=user
                     @addresses = UserPhoneBook.find(:all,:conditions => ["user_id LIKE ?",session[:user_id] ])
                     #~ @add_first =  UserPhoneBook.find(:first,:conditions => ["default_address = 1 AND user_id LIKE ?",session[:user_id] ])
                   
                   if user
                     user.update_attributes(:mobile_number => params[:from_phone],:address =>params[:from_street],:country=> params[:mycountry] ,:city=>params[:from_city],
              :state=>params[:from_state],:zipcode =>params[:from_zipcode] )
                   end
         end  
   
    render :partial => "step1_sucess" and return

 end

 def cart_item

  render :text=> "Size= #{session[:cart].items.size},variant_value---#{session[:cart].items[0].variant_value}, Quantity---#{session[:cart].items[0].quantity} ,Product id ---#{session[:cart].items[0].product_id}, 
  Total == #{cart_grand_total(session[:cart].items)}" and return
 end
 
   
     def order_items_list
        @account = getAccount()
      
     @cart = session[:cart]
      if request.post?
     #~ if  session[:order_id].blank?
        @order = Order.new
        @order.time_created = Time.now
        @order.customer_id = @account.id
        @order.status = "New"
        @order.iplocation = (RAILS_ENV == 'development') ? '203.193.173.102' : request.remote_ip
            #~ render :text=>session[:user_address_from].inspect and return
        @order.order_browser = request.env['HTTP_USER_AGENT']
        @order.order_ipaddress = request.env['HTTP_X_FORWARDED_FOR']
        @order.from_name = session[:user_address_from][:from_name]
        @order.from_email = session[:user_address_from][:from_email]
        @order.from_phone = session[:user_address_from][:from_phone]
        @order.from_zipcode = session[:user_address_from][:from_zipcode] 
        @order.from_street = session[:user_address_from][:from_street]
        @order.from_country = session[:user_address_from][:from_country]
        @order.from_state = session[:user_address_from][:from_state]
          @order.from_city = session[:user_address_from][:from_city]
        #~ @order.from_dob = session[:user_address_from][:from_dob]

 #~ render :text=>session[:user_address_to].inspect and return
         
        @order.to_steet = session[:user_address_to][:address]
        @order.to_zipcode = session[:user_address_to][:zipcode]
        @order.to_phone_no = session[:user_address_to][:phone]
          @order.to_country = session[:user_address_to][:country]
          @order.to_state = session[:user_address_to][:state]
          @order.to_city = session[:user_address_to][:city]
        @order.to_delivery_date = session[:user_address_to][:delivery_date].to_date 
        @order.to_name = session[:user_address_to][:title]     
          @order.note=session[:user_address_to][:note] 
          @order.to_name_user = session[:user_address_to][:to_name_user]
         if @order.save!         
                   
          session[:order_id] = @order.id
          @pnr_number = @order.id
          @note= @order.note
          @total_amount = cart_grand_total(session[:cart].items)
          session[:total] =@total_amount 
            saved_items = []
         
        @mer_emails_arr = []
        @mer_mobile_arr = []
          # create order items
                  
          for item in @cart.items
            product = Product.find(item.product_id)
          # render :text => product.merchant.email and return
         
        unless product.merchant.email.blank?
         if !@mer_emails_arr.include?(product.merchant.email)
            @mer_emails_arr.push(product.merchant.email)
        end
        session[:merchant_mails] = @mer_emails_arr
          
        end
        unless product.merchant.mobile.blank?
         if !@mer_mobile_arr.include?(product.merchant.mobile)
           @mer_mobile_arr.push(product.merchant.mobile) 
        end
        session[:merchant_mobiles] = @mer_mobile_arr
        end
  
            orderitem = Orderitem.new
            orderitem.order_id = @order.id
            orderitem.product_id = item.product_id
            orderitem.customer_id =@order.customer_id
            session[:find_order] = @order.id

       
            #~ render :text => session[:find_order] and return
            pa = ProductValue.find(:first,:conditions=>["product_id LIKE ? AND price LIKE ?",item.product_id,item.variant_value.to_i])
               #~ render :text =>item.variant_value.inspect and return
               if !pa.blank?
                      orderitem.variant_value = pa.weight
                      #~ price_in_order = item.variant_value
                      price_in_order =  pa.price
              elsif product.status == 1
                     #~ p_variant = ProductValue.find(:first,:conditions=>["product_id LIKE ?",item.product_id])
                  p_variant = ProductValue.find(:first,:conditions=>["product_id LIKE ? AND price LIKE ?",item.product_id,item.variant_value.to_i])

                    orderitem.variant_value = p_variant.weight
                    #~ price_in_order = product.price
                   #~ price_in_order = item.variant_value
                   price_in_order = p_variant.price
              else
                 price_in_order = product.price
              end

          
          
            orderitem.price_in_order = price_in_order
            orderitem.quantity = item.quantity
            #~ orderitem.variant_value = item.variant_value
            
            if orderitem.save
              # saved
              saved_items << orderitem.id
            else  
              all_saved_without_error = false
            end
            
            
          end
          
          
      end

   end    

  end
     
  def faq
  end
  def switch_gifts

    render :partial => "switch_gifts" and return
       
     end
     
   def gift_login  
     session[:user_id]=nil
    if request.post?
      #~ render :text=> params[:url] and return
     user = User.authenticate(params[:username1], params[:password1])    
            if user
            
                  if user.email_confirmation == 1 && user.status == 1 && user.role_id ==3
                       session[:user_id] = user.id
                     @user=user
                     session[:gift_url] = 'gift_login'
                     session[:for_ie] = 'iebrowser'
                     flash[:existed_user_login_error] = ""
                     flash[:registered_user_error] = ""
                     redirect_to :action => :gift_page and return
                
                else
                flash[:existed_user_login_error] = "Please check your Email for activation email and activate your account. If you did not find the activation Email in your <b>Inbox</b>, please check your <b>spam</b> folder."
                redirect_to :action => :gift_page and return
               end 
	       else
               flash[:existed_user_login_error] = "Invalid Email ID or Password"
                flash[:registered_user_error] = ""
                redirect_to :action => :gift_page and return
         end       
       end
       
             redirect_to :action => :gift_page and return

 end  
   
def guest_user_login
    @user = User.new(params[:user])
    @user.created_at = $indian_time.now.to_date
    @user.updated_at=  $indian_time.now.to_date
    num=User.random(8)
    @user.invitation_code =num
    @roles1= Role.find_by_title("User")
    @user.role_id =@roles1.id  
   
                    if @user.save
                      #~ session[:guest]='1'
                      session[:guest_user_id] = @user.id
                      #~ render :text => session[:guest_user_id] and return
                    EmailMailer.deliver_new_user(@user.name,@user.password, @user.email,@user.id)
                     
                         #~ flash[:notice] ="account" 
                         render :partial => "gift_login" and return
                     else
                        flash[:registered_user_error] ="User already exist with this email." 
                        flash[:existed_user_login_error] = ""
                         render :partial  => "invalid_email" and return

                  end   

end



     
   
  private

 def cart_grand_total(total_items)
  my_total = 0 

  for gift in total_items
   p = Product.find(gift.product_id) 
   unit_price = p.price 
 
			if gift.variant_value.to_i == 0 			
			   unit_price = p.price				
		 else 
			  unit_price = gift.variant_value.to_f				
		end      
      
      
    final_price = unit_price * gift.quantity 
    my_total += final_price 
 end
  return my_total
end





  def getAccount()
    if session[:user_id] != nil
      account = User.find(session[:user_id])
      return account
    elsif session[:guest_user_id] != nil
          account = User.find(session[:guest_user_id])
          return account
    end    
  end  
  
  
  
  # modified code ------------------
  
  def getaccount_info    
    session[:user_id] != nil ? User.find(session[:user_id]) : nil
  end
  
  def get_seo_info(product=nil)
       if !product
         @shoppingseocontent=Seo.find(:first,:select=>"title,description,keywords",:conditions=>["pagename LIKE ?","Shopping Home"])
         @pagetitle= @shoppingseocontent.title
         @pagedescription=@shoppingseocontent.description
         @pagekeywords=@shoppingseocontent.keywords 
      else
          @pagetitle = "Product - " + product.title
          @pagedescription=(product.details).gsub(/(<[^>]*>)|\n|\t|\&nbsp;|/s, "").slice(0,300)
         @pagekeywords=product.keywords      
      end
  end
  
   def similar_products(product)
       latestproduct = ProductCategory.find(:first,:conditions => ["product_id = #{product.id}"])
       if latestproduct
       @category = ShoppingCategory.find(latestproduct.shopping_category_id)
       @myarr = []
        category_list= ProductCategory.find(:all, :conditions=>["shopping_category_id = ? ", @category.id])
        for cat in category_list
          @myarr << cat.product_id 
        end

      if !@myarr.blank?
        @similar_products = Product.paginate(:per_page => 6,:page=>params[:similar_products_page],:conditions => ["id in (#{@myarr.join(',')}) AND id != #{product.id} AND status=1"])
      end  
        end 
  end
   
   def featured_product(product)
   @featureproduct =  Product.paginate(:per_page =>2, :page=>params[:featureproduct_page], :conditions => ["featured = ? and id != ? AND status =1", 1, product.id], :order=>'id desc',  :limit => 3)
   end
  
  def ordered_items(product)
    @ordered = Orderitem.find(:all,:conditions=>  ["product_id = ?", params[:id]] )
  end
  # end of modified code ----------------
  
end
