tamboti = {};

$(document).ready(function() {
    $("#filters-renderer").on("click", "div", function() {alert("click");
        var $this = $(this);
        
        $this.toggleClass("selected-filter-view");
        
        var filterId = this.id;
        var filterUrl = "../../modules/filters/" + filterId.replace("i-i18n", "") + ".xql";
    });
});
