/*Code adapted from Chris Coyier's jquery.ie6blocker.js, <http://css-tricks.com/ie-6-blocker-script/>*/
var IE = (navigator.userAgent.indexOf("MSIE 6")>=0 || navigator.userAgent.indexOf("MSIE 7">=0)>=0) ? true: false;
if(IE){

	$(function(){
		
		$("<div>")
			.css({
				'position': 'absolute',
				'top': '0px',
				'left': '0px',
				backgroundColor: 'black',
				'opacity': '0.50',
				'width': '100%',
				'height': $(window).height(),
				zIndex: 5000
			})
			.appendTo("body");
			
		$("<div><p><br /><strong>Sorry! Tamboti does not work with versions of Internet Explorer below version 8.</strong><br /><br />If you would like to access Tamboti, please use a recent version of <a href='http://windows.microsoft.com/en-US/internet-explorer/products/ie/home'>Internet Explorer</a>, <a href='http://getfirefox.org'>Firefox</a>, <a href='https://www.google.com/chrome/'>Chrome</a>, or <a href='http://www.apple.com/safari/download/'>Safari</a>.</p>")
			.css({
				'font-size':'125%',
				backgroundColor: 'white',
				'top': '50%',
				'left': '50%',
				marginLeft: -210,
				marginTop: -100,
				width: 410,
				paddingRight: 10,
				height: 200,
				'position': 'absolute',
				zIndex: 6000
			})
			.appendTo("body");
	});		
}