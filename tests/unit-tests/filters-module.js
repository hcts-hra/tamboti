tamboti = {};

$(document).ready(function() {
    wrapper = document.getElementById("filters-renderer-container");
    
    wrapper.addEventListener("scroll", function (event) {
        var offsets = this.getBoundingClientRect();
        var topOffset = offsets.top;
        var leftOffset = offsets.left;
        var rightOffset = offsets.right;
        var bottomOffset = offsets.bottom;
        var firstDisplayedFilterElement = document.elementFromPoint(leftOffset, topOffset + 17);
        var lastDisplayedFilterElement = tamboti.filters.actions['getLastDisplayedFilterElement'](rightOffset, bottomOffset);
        
        var firstDisplayedFilterIndex = firstDisplayedFilterElement.textContent;
        if (firstDisplayedFilterElement.id == "filters-renderer-container") {
            firstDisplayedFilterIndex = "firstDisplayedFilterIndex";
        }
        var lastDisplayedFilterIndex = lastDisplayedFilterElement.textContent;
        if (lastDisplayedFilterElement.id == "filters-renderer-container") {
            lastDisplayedFilterIndex = "lastDisplayedFilterIndex";
        }
        
        way.set("dataInstances.variables.firstFilterDisplayedIndex", firstDisplayedFilterIndex);
        way.set("dataInstances.variables.lastFilterDisplayedIndex", lastDisplayedFilterIndex);        
        
    //     var filters = way.get("dataInstances.filters");
    //     var lastFilterDisplayedIndex = way.get("dataInstances.variables.lastFilterDisplayedIndex");
    //     var threshold = 0; // how many pixels past the viewport an element has to be to be removed.
        
    //     $('.filter-view').each(function () {
    //         var $this = $(this);
            
    //         if ($this.offset().top + $this.height() + threshold < $(window).scrollTop()) {       
    //             $this.remove();
    //             way.set("dataInstances.variables.lastFilterDisplayedIndex", lastFilterDisplayedIndex + 1);
    //         } 
    //     });
        
    //     if (lastFilterDisplayedIndex <= filters.length + 1) {
    //         checkForNewDiv();
    //     }
    });
    
    // filterDiv = document.createElement('div');
    // filterDiv.setAttribute("class", "filter-view");    
    // var containerScrollTop = wrapper.scrollTop;
    // var pageOffset = containerScrollTop + wrapper.clientHeight;
    // var incrementingValue = 10;    
    // checkForNewDiv = function () {
    //     var mostVisibleItem = $("#filters-renderer > div:visible");
    //     //alert(mostVisibleItem.size());

    //     var lastDiv = document.querySelector("#filters-renderer > div:last-child");
    //     var lastDivOffset = lastDiv.offsetTop + lastDiv.clientHeight;
    //     var pageOffset = wrapper.scrollTop + wrapper.clientHeight;
    //     var filters = way.get("dataInstances.filters");
    //     var lastFilterDisplayedIndex = way.get("dataInstances.variables.lastFilterDisplayedIndex");
    //     var incrementingValue = 10;
        
    //     if (pageOffset > lastDivOffset - 10 && lastFilterDisplayedIndex <= filters.length) {
    //         for (var i = 0; i < incrementingValue; i++) {
    //             var filterDiv = document.createElement('div');
    //             filterDiv.setAttribute("class", "filter-view");
    //             filterDiv.innerHTML = filters[lastFilterDisplayedIndex + i]['#text'] + ' [' + filters[lastFilterDisplayedIndex + i]['frequency'] + ']';
    //             document.getElementById("filters-renderer").appendChild(filterDiv.cloneNode(true));
    //         }
            
    //         way.set("dataInstances.variables.lastFilterDisplayedIndex", lastFilterDisplayedIndex + incrementingValue);
            
    //         checkForNewDiv();
    //     } else if (pageOffset < lastDivOffset - 10) {
    //         console.log("upscroll code");
    //     }
    // };

    $("#filters-renderer").on("click", "div", function() {
        var $this = $(this);
        
        $this.toggleClass("selected-filter-view");
        
        var filterId = this.id;
        var filterUrl = "../../modules/filters/" + filterId.replace("i-i18n", "") + ".xql";
    });
});
