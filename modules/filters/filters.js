tamboti.filters = {};

tamboti.filters.dataInstances = {};
tamboti.filters.dataInstances['original-filters'] = [];
tamboti.filters.dataInstances['filters'] = [];
tamboti.filters.dataInstances['original-filters'] = [];

way.set("dataInstances", {
    "variables": {
        "firstFilterDisplayedIndex": "0",
        "lastFilterDisplayedIndex": "0",
        "totalFiltersNumber": "0"
    }
});     

tamboti.filters.actions = {};
tamboti.filters.actions['removeFilters'] = function() {
    var filterRenderer = document.getElementById("filters-renderer");
    
    var cNode = filterRenderer.cloneNode(false);
    filterRenderer.parentNode.replaceChild(cNode, filterRenderer);        
    filterRenderer = cNode;
};    
tamboti.filters.actions['renderFilters'] = function(filters) {
    tamboti.filters.actions['removeFilters']();
    
    var filterRenderer = document.getElementById("filters-renderer");
    
    var filterDiv = document.createElement('div');
    var docFragment = document.createDocumentFragment();
    
    var filtersNumber = filters.length;
        
    for (var i = 0; i < filtersNumber; i++) {
        filterDiv.textContent = filters[i]['#text'] + ' [' + filters[i]['frequency'] + ']';
        docFragment.appendChild(filterDiv.cloneNode(true));
    } 
    
    filterRenderer.appendChild(docFragment);
};
tamboti.filters.actions['sortFilters'] = function(sortButton) {
    var sortToken = sortButton.className;
    var sortToken = sortToken.substring(sortToken.indexOf("fa-sort-") + 8);
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
                return a["#text"].localeCompare(b["#text"]);
            });                
        }
        
        if (sortOrder == "desc") {
            sortedFilters = filters.sort(function(a, b) {
                return b["#text"].localeCompare(a["#text"]);
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
};

tamboti.filters.actions['applyExcludes'] = function(data, exclusions) {
    var regexp = new RegExp(exclusions);
    var result = data.filter(function(item){
        return !regexp.test(item.filter);
    });
    
    return result;
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
        
        // tamboti.filters.table.ajax.url("../filters/" + filterName + ".xql");
        // tamboti.filters.table.load();
    });
    
    //tamboti.filters.table = $('#example').DataTable(tamboti.filters.tableDefinition);
});
