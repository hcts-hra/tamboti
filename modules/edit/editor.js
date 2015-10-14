$(function() {

	// this function has to be removed when the tabs will be completely refactored
    window.activateBotttomTab = function(tabIndex) {
		$("table.bottom-tabs tr:first-child td").each(function() {
		    $(this).css("background", "#ededed").css("border-bottom-color", "#bebebe");
		});
		$("table.bottom-tabs tr:first-child td:eq(" + tabIndex + ")").css("background", "white").
		css("border-bottom-color", "white").css("color", "#3681B3");
    }
   
});
