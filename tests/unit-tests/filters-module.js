tamboti = {};

$(document).ready(function() {
    wrapper = document.getElementById("filters-renderer-container");
    
    wrapper.addEventListener("scroll", function (event) {
        var $this = this;
        
        var offsets = $this.getBoundingClientRect();
        var topOffset = offsets.top;
        var leftOffset = offsets.left;
        var rightOffset = offsets.right;
        var bottomOffset = offsets.bottom;
        
        //var lineHeight = $this.style.lineHeight;
        
        var firstDisplayedFilterElement = document.elementFromPoint(leftOffset, topOffset + 17);
        
        var firstDisplayedFilterIndex = firstDisplayedFilterElement.textContent;
        if (firstDisplayedFilterElement.id == "filters-renderer-container") {
            firstDisplayedFilterIndex = "firstDisplayedFilterIndex";
        }
        
        var lastDisplayedFilterIndex = tamboti.filters.actions['getLastDisplayedFilterIndex'](rightOffset, bottomOffset);
        
        way.set("dataInstances.variables.firstDisplayedFilterIndex", firstDisplayedFilterIndex);
        way.set("dataInstances.variables.lastDisplayedFilterIndex", lastDisplayedFilterIndex);        
    });

    $("#filters-renderer-container").on("click", "div", function() {
        var $this = $(this);
        
        $this.toggleClass("selected-filter-view");
        
        var filterId = this.id;
        var filterUrl = "../../modules/filters/" + filterId.replace("i-i18n", "") + ".xql";
    });
});
