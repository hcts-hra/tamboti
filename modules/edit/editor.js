$(function() {

	// this function has to be removed when the tabs will be completely refactored
    function activateBotttomTab(tabIndex) {
        $("table.bottom-tabs tr:first-child" td).each(function() {
            $(this).css("background", "#EDEDED");
        });
    }
   
});
