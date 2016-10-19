$(document).ready(function() {
    tamboti = {};
    tamboti.filters = {};
    
    tamboti.filters.filterName = "";
    tamboti.filters.dataInstances = {};
    tamboti.filters.actions = {};
    tamboti.filters.actions[''] = function() {
        
    };
    tamboti.filters.dataInstances['filters'] = {};
    tamboti.filters.dataInstances['variables'] = {};
    
    wrapper = document.getElementById("filters-renderer-container");
    $wrapper = $(wrapper);
    
    filterDiv = document.createElement('div');
    filterDiv.setAttribute("class", "filter-view");
    
    //var filtersLength = filters.length;
    tamboti.filters.dataInstances['variables'].lastFilterDisplayed = 0;
    
    wrapper.addEventListener("scroll", function (event) {
        var filters = tamboti.filters.dataInstances['filters']['filter'];
        var lastFilterDisplayed = tamboti.filters.dataInstances['variables'].lastFilterDisplayed;
        
        var threshold = 0; // how many pixels past the viewport an element has to be to be removed.
        $('.filter-view').each(function () {
            var $this = $(this);
            
            if ($this.offset().top + $this.height() + threshold < $(window).scrollTop()) {       
                $this.remove();
            } 
        });
        
        checkForNewDiv();
    });
    
    checkForNewDiv = function () {
        var lastDiv = document.querySelector("#filters-renderer > div:last-child");
        var lastDivOffset = lastDiv.offsetTop + lastDiv.clientHeight;
        var pageOffset = wrapper.scrollTop + wrapper.clientHeight;
        var filters = tamboti.filters.dataInstances['filters']['filter'];
        var lastFilterDisplayed = tamboti.filters.dataInstances['variables'].lastFilterDisplayed;
        
        if (pageOffset > lastDivOffset - 10) {
            for (var i = 0; i < 10; i++) {
                var filterDiv = document.createElement('div');
                filterDiv.setAttribute("class", "filter-view");
                filterDiv.innerHTML = filters[lastFilterDisplayed + i]['#text'] + ' [' + filters[lastFilterDisplayed + i]['frequency'] + ']';
                document.getElementById("filters-renderer").appendChild(filterDiv.cloneNode(true));
                tamboti.filters.dataInstances['variables'].lastFilterDisplayed++;
            }
            
            checkForNewDiv();
        } else if (pageOffset < lastDivOffset - 10) {
            console.log("upscroll code");
        }
    };

    
    

    $("#filters-renderer-container").on("click", "div.filter-view", function() {
        var $this = $(this);
        
        $this.addClass("selected-filter-view");
        
        var filterId = this.id;
        var filterUrl = "../../modules/filters/" + filterId.replace("i-i18n", "") + ".xql";
    });
});
                