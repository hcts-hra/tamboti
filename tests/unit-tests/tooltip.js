$(document).ready(function() {
  $('a').qtip({
		content: function() {
		  var element = $(this);
		  var caption = element.find("div.vra-record").html();
		  
		  return $("<div class='vra-record'>" + caption + "</div>");
		},
	    position: {
	    	target: 'mouse',
	        adjust: { x: 5, y: 5 }
	    },
	    style: {
	        classes: 'qtip-light'
	    }	    
	});
	
	$("a img").qtip({
		content: function() {
		  var element = $(this);
		  var src = element.attr("src");
		  
		  return $("<img class='image-tooltip' alt='" + element.attr("alt") + "' src='" + src + "' />");
		},	    
	    position: {
	    	target: 'mouse',	    
	        adjust: { x: -170, y: -110 }
	    },
	    style: {
	        classes: 'qtip-light'
	    }
	});
});