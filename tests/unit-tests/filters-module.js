$(document).ready(function() {
    tamboti = {};
    tamboti.filters = {};
    
    tamboti.filters.filterName = "";
    tamboti.filters.dataInstances = {};
    tamboti.filters.actions = {};
    tamboti.filters.actions[''] = function() {
        
    };
    tamboti.filters.dataInstances['filters'] = {};
    tamboti.filters.dataInstances['filters2'] = new Backbone.Model({
      "filters": new Backbone.Collection([])
    });
    tamboti.filters.dataInstances['variables'] = {};
    tamboti.filters.dataInstances['variables2'] = Backbone.Epoxy.Model.extend({
        defaults: {
            firstFilterDisplayedIndex: 0,
            lastFilterDisplayedIndex: 0
        },
        computeds: {
            totalFiltersNumberFunction: function() {
                    return tamboti.filters.dataInstances['filters2'].get("filters").size() || 0;
            }
        }        
    });
    
    var BindingView = Backbone.Epoxy.View.extend({
        el: "#filters-navigator",
        model: new tamboti.filters.dataInstances['variables2'](),
        bindings: {
            "span#filters-firstFilterDisplayedIndex": "text:firstFilterDisplayedIndex",
            "span#filters-lastFilterDisplayedIndex": "text:lastFilterDisplayedIndex",
            "span#filters-totalFiltersNumber": "text:totalFiltersNumberFunction"
        }
    });    
    
    new BindingView();    
    
    
    
    
    
    wrapper = document.getElementById("filters-renderer-container");
    $wrapper = $(wrapper);
    
    filterDiv = document.createElement('div');
    filterDiv.setAttribute("class", "filter-view");
    
    //var filtersLength = filters.length;
    tamboti.filters.dataInstances['variables'].lastFilterDisplayedIndex = 0;
    
    wrapper.addEventListener("scroll", function (event) {
        var filters = tamboti.filters.dataInstances['filters']['filter'];
        var lastFilterDisplayedIndex = tamboti.filters.dataInstances['variables'].lastFilterDisplayedIndex;
        
        var threshold = 0; // how many pixels past the viewport an element has to be to be removed.
        $('.filter-view').each(function () {
            var $this = $(this);
            
            if ($this.offset().top + $this.height() + threshold < $(window).scrollTop()) {       
                $this.remove();
                tamboti.filters.dataInstances['variables2'].set("firstFilterDisplayedIndex", tamboti.filters.dataInstances['variables2'].get("firstFilterDisplayedIndex") + 1);
            } 
        });
        
        checkForNewDiv();
    });
    
    checkForNewDiv = function () {
        var lastDiv = document.querySelector("#filters-renderer > div:last-child");
        var lastDivOffset = lastDiv.offsetTop + lastDiv.clientHeight;
        var pageOffset = wrapper.scrollTop + wrapper.clientHeight;
        var filters = tamboti.filters.dataInstances['filters']['filter'];
        var lastFilterDisplayedIndex = tamboti.filters.dataInstances['variables'].lastFilterDisplayedIndex;
        var incrementingValue = 10;
        
        if (pageOffset > lastDivOffset - 10) {
            for (var i = 0; i < incrementingValue; i++) {
                var filterDiv = document.createElement('div');
                filterDiv.setAttribute("class", "filter-view");
                filterDiv.innerHTML = filters[lastFilterDisplayedIndex + i]['#text'] + ' [' + filters[lastFilterDisplayedIndex + i]['frequency'] + ']';
                document.getElementById("filters-renderer").appendChild(filterDiv.cloneNode(true));
            }
            
            tamboti.filters.dataInstances['variables2'].set("lastFilterDisplayedIndex", tamboti.filters.dataInstances['variables2'].get("lastFilterDisplayedIndex") + incrementingValue);
            
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

// var start = performance.now();

// console.log(tamboti.filters.dataInstances['filters2'].get("filters").at(1).attributes["#text"]);

// var end = performance.now();

// console.log("Op. took " + (end - start) + "ms.");

// var dataInstance = {
//   filters: 22
// }

// var handler = {
//   set: function(target, property, value, receiver) {
//     console.log("set() property = " + property);
//     console.log("set() value = " + value);
//     console.log("set() receiver = " + JSON.stringify(receiver));
//     document.getElementById("filters-totalFiltersNumber").textContent = value;
//   }
// };

// var target = document.getElementById("filters-totalFiltersNumber");

// var dataInstanceProxy = new Proxy(dataInstance, handler);


// dataInstanceProxy.filters = 17;

// console.log(JSON.stringify(dataInstanceProxy));

