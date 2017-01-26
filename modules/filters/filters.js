tamboti.filters = {};

tamboti.filters.dataInstances = {};
tamboti.filters.dataInstances['original-filters'] = [];
tamboti.filters.dataInstances['filters'] = [];
way.set("dataInstances", {
    "variables": {
        "firstDisplayedFilterIndex": "0",
        "lastDisplayedFilterIndex": "0",
        "totalFiltersNumber": "0"
    }
});     

tamboti.filters.actions = {};
tamboti.filters.actions['getFiltersRendererId'] = function() {return "filters-renderer"};
tamboti.filters.actions['removeFilters'] = function() {
    var filtersRenderer = document.getElementById(tamboti.filters.actions['getFiltersRendererId']());
    
    var cNode = filtersRenderer.cloneNode(false);
    filtersRenderer.parentNode.replaceChild(cNode, filtersRenderer);        
    filtersRenderer = cNode;
    
    filtersRenderer.addEventListener("scroll", function (event) {
        tamboti.filters.actions['setDisplayedFiltersIndexes'](0);
    });     
};    
tamboti.filters.actions['renderFilters'] = function(filters) {
    tamboti.filters.actions['removeFilters']();
    
    var filterRenderer = document.getElementById(tamboti.filters.actions['getFiltersRendererId']());
    
    var filterDiv = document.createElement('div');
    var docFragment = document.createDocumentFragment();
    
    var filtersNumber = filters.length;
        
    for (var i = 0; i < filtersNumber; i++) {
        filterDiv.textContent = filters[i]['label'] + ' [' + filters[i]['frequency'] + ']';
        filterDiv.dataset.index = i + 1;
        docFragment.appendChild(filterDiv.cloneNode(true));
    } 
    
    filterRenderer.appendChild(docFragment);
        
    tamboti.filters.actions['setDisplayedFiltersIndexes'](filtersNumber);
};
tamboti.filters.actions['sortFilters'] = function(sortButton) {
    fluxProcessor.dispatchEventType("body", "filters:start-processing", {});
    
    var sortToken = sortButton.className;
    sortToken = sortToken.substring(sortToken.indexOf("fa-sort-") + 8);
    var sortBy = sortToken.substring(0, sortToken.indexOf("-"));
    var sortOrder = sortToken.substring(sortToken.indexOf("-") + 1);
    
    var filters = tamboti.filters.dataInstances['filters'];
    var sortedFilters;
    
    if (sortBy == "amount") {
        if (sortOrder == "asc") {
            sortedFilters = filters.sort(function(a, b) {
                return a.frequency - b.frequency;
            });                
        }
        
        if (sortOrder == "desc") {
            sortedFilters = filters.sort(function(a, b) {
                return b.frequency - a.frequency;
            });                
        }            
    }
    
    if (sortBy == "alpha") {
        if (sortOrder == "asc") {
            sortedFilters = filters.sort(function(a, b) {
                return a["label"].localeCompare(b["label"]);
            });                
        }
        
        if (sortOrder == "desc") {
            sortedFilters = filters.sort(function(a, b) {
                return b["label"].localeCompare(a["label"]);
            });                
        }            
    }        
    
    tamboti.filters.actions['renderFilters'](sortedFilters);
    tamboti.filters.dataInstances['filters'] = sortedFilters;        
    
    if (sortBy == "amount") {
        sortButton.classList.toggle("fa-sort-amount-asc", sortOrder == "desc");
        sortButton.classList.toggle("fa-sort-amount-desc", sortOrder == "asc");            
    }
    
    if (sortBy == "alpha") {
        sortButton.classList.toggle("fa-sort-alpha-asc", sortOrder == "desc");
        sortButton.classList.toggle("fa-sort-alpha-desc", sortOrder == "asc");            
    } 
    
    tamboti.filters.actions['setDisplayedFiltersIndexes'](sortedFilters.length);
    
    fluxProcessor.dispatchEventType("body", "filters:end-processing", {});
};

tamboti.filters.actions['applyExclusions'] = function() {
    var data = tamboti.filters.dataInstances['original-filters'];
    var exclusions = tamboti.filters.actions['getExclusions']();
    
    var result = data;
    
    if (exclusions !== '') {
        var regexp = new RegExp(exclusions);
        
        result = data.filter(function(item){
            return !regexp.test(item.filter);
        });
    }
    
    tamboti.filters.dataInstances['filters'] = result;
    
    return result;
};

tamboti.filters.actions['getExclusions'] = function() {
    var exclusionInputElements = document.querySelectorAll("#exclusions-select input[type = 'checkbox']:checked");
    
    var exclusions = Array.prototype.map.call(exclusionInputElements, function(exclusionInputElement) {
        return exclusionInputElement.value;
    }).join('|');    

    return exclusions;
};

tamboti.filters.actions['getLastDisplayedFilterIndex'] = function(rightOffset, bottomOffset, filterElementHeight, filterElementWidth) {
    var lastDisplayedFilterElement = document.elementFromPoint(rightOffset, bottomOffset - filterElementHeight);
    
    if (lastDisplayedFilterElement !== null) {
        if (lastDisplayedFilterElement.parentNode.id != tamboti.filters.actions['getFiltersRendererId']()) {
            return tamboti.filters.actions['getLastDisplayedFilterIndex'](rightOffset - filterElementWidth / 2, bottomOffset, filterElementHeight, filterElementWidth);
        } else {
            return lastDisplayedFilterElement.dataset.index;
        }        
    }
};

tamboti.filters.actions['setDisplayedFiltersIndexes'] = function(totalFiltersNumber) {
    var firstFilterElement = document.querySelector("#" + tamboti.filters.actions['getFiltersRendererId']() + " > div");
    
    if (firstFilterElement === null) {
        return;    
    }
    
    var filterRenderer = document.getElementById(tamboti.filters.actions['getFiltersRendererId']());
    
    if (filterRenderer.scrollHeight == filterRenderer.clientHeight) {
        way.set("dataInstances.variables.lastDisplayedFilterIndex", totalFiltersNumber); 
        return;    
    }    
    
    var offsets = filterRenderer.getBoundingClientRect();
    var topOffset = offsets.top;
    var leftOffset = offsets.left;
    var rightOffset = offsets.right;
    var bottomOffset = offsets.bottom;
    
    var filterElementOffsets = firstFilterElement.getBoundingClientRect(); 
    var filterElementHeight = filterElementOffsets.height;
    var filterElementWidth = filterElementOffsets.width;
    
    var firstDisplayedFilterIndex = document.elementFromPoint(leftOffset, topOffset + filterElementHeight).dataset.index;
    var lastDisplayedFilterIndex = tamboti.filters.actions['getLastDisplayedFilterIndex'](rightOffset, bottomOffset, filterElementHeight, filterElementWidth);
    
    way.set("dataInstances.variables.firstDisplayedFilterIndex", firstDisplayedFilterIndex);
    way.set("dataInstances.variables.lastDisplayedFilterIndex", lastDisplayedFilterIndex); 
};

$(document).ready(function() {
    $("#filters2-navigation").on("click", "a", function() {
        var $this = $(this);
        var filterId = this.id;
        tamboti.filters.filterId = filterId;
        var filterUrl = "../filters/" + filterId.replace("-filter", "") + ".xql";
        
        $("img", $this).show();
        
        $.ajax({
            url: filterUrl,
            dataType: "text",
            type: "GET",
            success: function (data) {
            	alert(JSON.parse(data));
            }
        });        
    });
    
    $("#filters").on("click", "#"+ tamboti.filters.actions['getFiltersRendererId']() + " > div", function() {
        var $this = $(this);
        
        $this.toggleClass("selected-filter-view");
        
        var filterId = this.id;
        var filterUrl = "../../modules/filters/" + filterId.replace("i-i18n", "") + ".xql";
        alert(filterUrl);
    });    
});
