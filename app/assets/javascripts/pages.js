$(document).ready(function(){

	$('.delete_page').on('ajax:success', function() {  
	        $(this).closest('tr').fadeOut("slow",function(){
	        	$(this).remove();
	        	i=1;
		        $(".position").each(function(){
		        	$(this).html(i);
		        	i++;
		        })
	        })

	}); 
});