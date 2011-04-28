# Methods added to this helper will be available to all templates in the application.
require 'date'
module ApplicationHelper



def sort_link_helper(text, param)
  key = param
  key += "_reverse" if params[:sort] == param
  options = {
      :url => {:action => 'list', :params => params.merge({:sort => key, :page => nil})},
      :update => 'table',
      :before => "Element.show('spinner')",
      :success => "Element.hide('spinner')"
  }
  html_options = {
    :title => "Sort by this field",
    :href => url_for(:action => 'list', :params => params.merge({:sort => key, :page => nil}))
  }
  link_to_remote(text, options, html_options)
end


def pagination_links_remote(paginator)
  page_options = {:window_size => 3}
  pagination_links_each(paginator, page_options) do |n|
    options = {
      :url => {:action => 'list', :params => params.merge({:page => n})},
      :update => 'table',
      :before => "Element.show('spinner')",
      :success => "Element.hide('spinner')"
    }
    html_options = {:href => url_for(:action => 'list', :params => params.merge({:page => n}))}
    link_to_remote(n.to_s, options, html_options)
  end
end

  
  def show_price_editor(pricelevel, product)
    price_set = true
    price_set = false if Pricelevelsmatrix.find(:all, :conditions=>["pricelevel_id = ? and product_id = ?", pricelevel.id, product.id]).size == 0
    
    if price_set
      pricematrix = Pricelevelsmatrix.find(:first, :conditions=>["pricelevel_id = ? and product_id = ?", pricelevel.id, product.id])
      
      "<span id=edit-pricelevel-#{pricelevel.id}-#{product.id}>#{pricematrix.price}</span><br/>
      <script>
      	new Ajax.InPlaceEditor('edit-pricelevel-#{pricelevel.id}-#{product.id}', 
      			'#{Shop.install_dir_name}/admin/update_ajax_price_matrix', 
      			{ callback: function(form, value) { 
      				return 'pricelevel_id=#{pricelevel.id}&product_id=#{product.id}&field=price&nvalue=' + escape(value) },
      				size:8});
      </script>"
      
    else
      newpricematrix = Pricelevelsmatrix.new
      newpricematrix.pricelevel_id = pricelevel.id
      newpricematrix.product_id = product.id
      newpricematrix.price = 0.0
      
      if newpricematrix.save
        "<span id=edit-pricelevel-#{pricelevel.id}-#{product.id}>#{newpricematrix.price}</span><br/>
        <script>
        	new Ajax.InPlaceEditor('edit-pricelevel-#{pricelevel.id}-#{product.id}', 
        			'#{Shop.install_dir_name}/admin/update_ajax_price_matrix', 
        			{ callback: function(form, value) { 
        				'pricelevel_id=#{pricelevel.id}&product_id=#{product.id}&field=price&nvalue=' + escape(value) },
        				size:8});
        </script>"
      else
        "Error"
      end    
    end
  end  
  
  def show_price_level(account)
    size = Pricelevel.find(:all, :conditions=>["id = ?", account.price_level_id]).size
    if size > 0
      return Pricelevel.find(account.price_level_id).title
    else
      return "Unknown"
    end    
    
  end
  

  def show_first_image(product)
    if product.images.size > 0
      image_tag(url_for_file_column(product.images[0], "image", "large"))
    else
      image_tag("/images/no-image.gif")
    end  
  end  
  
    def show_order_merchant_image(product)
    if product.images.size > 0
      image_tag(url_for_file_column(product.images[0], "image", "thubm"))
    else
      image_tag("/images/no-image.gif")
    end  
  end  
    
  def myshow_price(product, account,product_id)
    
    #price = price * (1 - discount_percentage.to_f/100)
    
    if account.nil?
      # Show price including Tax
      
      if Shop.is_tax_incl
        price = product
      else
        price = product * (1 + Shop.tax_rate/100)
      end

    else
      #pricelevel = account.pricelevel
      
      if account.price_level_id <= 1
        #retail price account, excl GST
        #price = product.price
        
        if Shop.is_tax_incl
          price = product
        else
          price = product * (1 + Shop.tax_rate/100)
        end
      else
        pricelevelsmatrix = Pricelevelsmatrix.find(:first, 
          :conditions=>["pricelevel_id = ? and product_id = ?", 
            account.price_level_id, 
            product_id])
        if pricelevelsmatrix != nil
          #price = pricelevelsmatrix.price
          
          if Shop.is_tax_incl
            price = pricelevelsmatrix.price
          else
            price = pricelevelsmatrix.price * (1 + Shop.tax_rate/100)
          end
          
        else
          if Shop.is_tax_incl
            price = product
          else
            price = product * (1 + Shop.tax_rate/100)
          end
        end    
        
      end
    end    
    
    return number_to_currency(price,:unit => " ")
  end  
  

  def show_price(product, account)
    
    #price = price * (1 - discount_percentage.to_f/100)
    
    if account.nil?
      # Show price including Tax
      
      if Shop.is_tax_incl
        price = product.price
      else
        price = product.price * (1 + Shop.tax_rate/100)
      end

    else
      #pricelevel = account.pricelevel
      
      if account.price_level_id <= 1
        #retail price account, excl GST
        #price = product.price
        
        if Shop.is_tax_incl
          price = product.price
        else
          price = product.price * (1 + Shop.tax_rate/100)
        end
      else
        pricelevelsmatrix = Pricelevelsmatrix.find(:first, 
          :conditions=>["pricelevel_id = ? and product_id = ?", 
            account.price_level_id, 
            product.id])
        if pricelevelsmatrix != nil
          #price = pricelevelsmatrix.price
          
          if Shop.is_tax_incl
            price = pricelevelsmatrix.price
          else
            price = pricelevelsmatrix.price * (1 + Shop.tax_rate/100)
          end
          
        else
          if Shop.is_tax_incl
            price = product.price
          else
            price = product.price * (1 + Shop.tax_rate/100)
          end
        end    
        
      end
    end    
    
    return number_to_currency(price,:unit => " ")
  end  
  
  def show_cart(cart, account)
    empty_line = "<tr><td></td><td></td><td></td><td></td></tr>"
    
    if cart != nil and cart.size > 0
      html = "<fieldset><legend>"
      html += "<strong>"
      html += "#{cart.size} item(s) in your shopping cart "
      
      #if @passed
      #html += link_to "(Click here to Place an Order)", :action=>'place_order',:controller =>"shopping"
      #else
      html += link_to(" [Click here to Place Order] ", {:action=>'place_order',:controller =>"gifts", :securitylevel=>"1"})
      #end    
      
      html += "</strong> </legend>"
      html +="<table class=carttable>"
      html +="<tr><th></th><th>Product</th><th>Quantity</th><th>Price</th><th>Remove</th></tr>"
      #sub_total = 0
      for item in cart.items
        p = Product.find(item.product_id)
        html += "<tr>"
        del_str = link_to( image_tag("/images/trash.gif"), { :action => 'delete_from_cart', :pid => p }, :confirm => 'Are you sure to remove this product from your shopping cart?', :method => :post)
        img_str = show_product_image(p, "thumb")
        final_price = p.price_for_account(account)
        #final_price = final_price * (1 - account.discount_percentage.to_f/100)
        final_price = final_price * item.quantity
        inc_str = link_to(image_tag("/images/increase.gif"),{:action=>'add_to_cart', :pid=>p.id}, :method => :post)
        dec_str = ""
        dec_str = link_to(image_tag("/images/decrease.gif"),{:action=>'decrease_quantity', :pid=>p.id}, :method => :post) if item.quantity >= 2
        quan_str = inc_str + "&nbsp;&nbsp;&nbsp;" + item.quantity.to_s + "&nbsp;&nbsp;&nbsp;" + dec_str
        html += "<td>#{img_str}</td><td>#{p.title}</td><td>#{quan_str}</td><td>#{number_to_currency final_price}</td><td>#{del_str}</td>" 
        html += "</tr>"
        #sub_total += p.price
      end
      
      #html += empty_line
      html +="<tr><td></td><td>Sub total</td><td></td><td>#{number_to_currency cart.sub_total}</td><td></td></tr>"
      html +="<tr><td></td><td>#{Shop.tax_code_name}</td><td></td><td>#{number_to_currency cart.tax_amount}</td><td></td></tr>"
      html +="<tr><td></td><td>Total</td><td></td><td>#{number_to_currency cart.total}</td><td></td></tr>"
      
      html +="</table>"
      html += "</fieldset>"
      
    else
      ""
    end  
  end  
  
  def show_product_image(product, size)
    
    numImages = product.images.size
    if numImages > 0
      img = product.images[0]
      if !img.image.blank?
      return link_to(image_tag(url_for_file_column(img, "image", size),:alt=>"#{product.title}",:title=>"#{product.title}",:style=>"border:solid 0px #cccccc;"), :action=>'product' , :controller =>"gifts", :id=>product.perma_link,:cat => product.shopping_category.perma_link)
      else
      return image_tag("/images/no-image-32.gif")
      end
    else
      if size == "thumb"
        return image_tag("/images/no-image-32.gif")
      else
        return image_tag("/images/no-image.gif")
      end    
    end    
  end
  
   def show_product_image_admin(product, size)
    
    numImages = product.images.size
    if numImages > 0
      img = product.images[0]
     
      if !img.image.blank?
      return image_tag(url_for_file_column(img, "image", size),:alt=>"Click to view large picture",:style=>"border:solid 0px #cccccc;")
      else
      return image_tag("/images/no-image-32.gif")
      end
    else
      if size == "thumb"
        return image_tag("/images/no-image-32.gif")
      else
        return image_tag("/images/no-image.gif")
      end    
    end    
  end
  
  def show_product_delivery(product)
    if product.delivery == 1
      return "Yes"
    else
      return "No"
    end    
  end
  
  def show_product_condition(product)
    
    c = Productcondition.find_all_by_id(product.condition_id)
    if c.size > 0
      return c[0].condition
    else
      return "Unknown"
    end    
  end  
  
  def show_product_warranty(product)
    c = Productwarranty.find_all_by_id(product.warranty_id)
    if c.size > 0
      return c[0].warranty
    else
      return "Unknown"
    end    
  end
  
 def show_sub_categories(category, level)
    script = "<script language='JavaScript' type='text/javascript'>
  		var ajax = new Ajax.InPlaceEditor('edit-category-name-#{category.id}', 
  				'#{Shop.install_dir_name}/admin/shopping/update_ajax_category_name', 
  				{ callback: function(form, value) { 
  					return 'id=#{category.id}&field=name&nvalue=' + escape(value) }, size:16 });
  	</script>"
  	
     html = level + "<span id='edit-category-name-#{category.id}'>" + category.name + "</span> (" +
      link_to(image_tag("/images/admin/delete.png"), { :controller=>'shopping_categories', :action => 'delete', :id => category.id}, 
      :confirm => 'Do you want to delete category <' + category.name  +  '>? This operation will move all products in this category to root category.', :method => 'post'),
      link_to(image_tag("/images/admin/edit.png"), { :controller=>'admin/shopping', :action => 'category_edit', :id => category.id}) ,
      link_to(image_tag("/images/admin/show.png"), { :controller=>'admin/shopping', :action => 'category_show', :id => category.id}),
      if category.status == 0 
     link_to(image_tag("/images/admin/inactive.jpg"), { :controller=>'admin/shopping', :action => 'category_status', :id => category.id})  
     else
     link_to(image_tag("/images/admin/active.jpg"), { :controller=>'admin/shopping', :action => 'category_status', :id => category.id}) 
    end + ")<br/>"  + script

    if category.number_of_sub_categories > 0
      
      for sub in category.sub_categories
        html += show_sub_categories(sub, level + level)
      end
      
    end
    return html
  end
  
  def show_admin_sub_categories(category, level)
    script = "<script language='JavaScript' type='text/javascript'>
  		var ajax = new Ajax.InPlaceEditor('edit-category-name-#{category.id}', 
  				'#{Shop.install_dir_name}/admin/shopping/update_ajax_category_name', 
  				{ callback: function(form, value) { 
  					return 'id=#{category.id}&field=name&nvalue=' + escape(value) }, size:16 });
  	</script>"
  	
     html = level + "<span id='edit-category-name-#{category.id}'>" + category.name + "</span> (" +
      link_to(image_tag("/images/admin/delete.png"), { :controller=>'shopping_categories', :action => 'delete', :id => category.id}, 
      :confirm => 'Do you want to delete category <' + category.name  +  '>? This operation will move all products in this category to root category.', :method => 'post'),
      link_to(image_tag("/images/admin/edit.png"), { :controller=>'admin/shopping', :action => 'category_edit', :id => category.id}) ,
      link_to(image_tag("/images/admin/show.png"), { :controller=>'admin/shopping', :action => 'category_show', :id => category.id}),
      if category.status == 0 
     link_to(image_tag("/images/admin/inactive.jpg"), { :controller=>'admin/shopping', :action => 'category_status', :id => category.id})  
     else
     link_to(image_tag("/images/admin/active.jpg"), { :controller=>'admin/shopping', :action => 'category_status', :id => category.id}) 
    end + ")<br/>"  + script

    if category.number_of_sub_categories > 0
      
      for sub in category.admin_sub_categories
        html += show_sub_categories(sub, level + level)
      end
      
    end
    return html
  end
  
  
  def show_sub_categories_for_fontpage_darken(category, level, query)
    category_name = category.name
    #~ main_category = ShoppingCategory.find_by_p_id(category.p_id)
    if category.label.include?(query)
      
    else
      category_name = "<span class='darken'>" + category_name.slice!(0..20) + "</span>"
    end
    
    if category.is_top_level_sub_categories
      html = level + link_to("<strong>" + category_name + "</strong>", :action=>'category', :id=>category.perma_link, :controller =>"gifts") + "<br/>"
    else
      html = level + link_to("&nbsp;&nbsp;"+category_name.slice!(0..21), :action=>'category', :id=>category.perma_link, :controller =>"gifts") + "<br/>"
    end    
    
    if category.number_of_sub_categories > 0
      
      for sub in category.sub_categories
        html += show_sub_categories_for_fontpage_darken(sub,level, query)
      end
    end
      
    return html
  end
  
  def show_sub_categories_for_fontpage_no_darken(category, level)
    
    if category.is_top_level_sub_categories
      html = level + link_to( "<strong>" + category.name + "</strong>" , :action=>'category', :id=>category.perma_link, :controller =>"gifts") + "<br/>"
    else
      html = level + link_to("&nbsp;&nbsp;"+category.name.slice!(0..21), :action=>'category', :id=>category.perma_link, :controller =>"gifts") + "<br/>"
    end    
    
    if category.number_of_sub_categories > 0
      
      for sub in category.sub_categories
        html += show_sub_categories_for_fontpage_no_darken(sub,level)
      end
    end
      
    return html
  end
  
  
  def show_category_structure(category, cid)
    
    if (cid == category.id)
      txt = category.name
    else
      txt = link_to(category.name, :action=>'category',:id=>category.perma_link,:controller =>"gifts")
    end  
    
    if (category.has_parent_category)
      txt = show_category_structure(category.parent_category, cid) + " - " + txt
    else  
      return txt
    end
  end
  
  def show_category_structure_with_link(category)
    
    txt = link_to(category.name.slice!(0..21), :action=>'category',:id=>category.perma_link,:controller =>"gifts")
    
    if (category.has_parent_category)
      txt = show_category_structure_with_link(category.parent_category) + " - " + txt
    else  
      return txt
    end
  end
  
  def text_with_br(txt)
    unless txt.blank?
    t = txt.gsub(/\n/,'W2Y_Br')
    t = t.gsub('&','&amp;')
    t = t.gsub('W2Y_Br', '<br/>')
    return t
    end
  end
  
  def show_merchants_format(merchant,format)
    return format + link_to(merchant.name.slice!(0..21) , :action=>'merchant', :id=>merchant.perma_link, :controller =>"gifts") 
  end
#shopping methods end

#method for displaying new image
def display_new_image(d1,d2)
  diff = DateTime.parse(d1) - DateTime.parse(d2) 
  time_diff,mi,seconds,frac = Date.send(:day_fraction_to_time, diff)
    if time_diff <=24
       true
    end
end


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









end
