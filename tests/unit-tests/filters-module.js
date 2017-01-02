tamboti = {};

$(document).ready(function() {
    $("#filters-renderer-container").on("click", "div", function() {
        var $this = $(this);
        
        $this.toggleClass("selected-filter-view");
        
        var filterId = this.id;
        var filterUrl = "../../modules/filters/" + filterId.replace("i-i18n", "") + ".xql";
    });
});
