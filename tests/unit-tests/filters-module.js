tamboti = {};

$(document).ready(function() {
    wrapper = document.getElementById("filters-renderer-container");
    $wrapper = $(wrapper);
    
    filterDiv = document.createElement('div');
    filterDiv.setAttribute("class", "filter-view");
    
    wrapper.addEventListener("scroll", function (event) {
        var filters = tamboti.filters.dataInstances['filters'];
        var displayedFilters = filters.slice(way.get("dataInstances.variables.firstFilterDisplayedIndex"));
        var displayedFiltersNumber = displayedFilters.length;
        var lastFilterDisplayedIndex = way.get("dataInstances.variables.lastFilterDisplayedIndex");
        var containerScrollTop = wrapper.scrollTop;
        var pageOffset = containerScrollTop + wrapper.clientHeight;
        var incrementingValue = 10;
        var filterFormControls = document.querySelectorAll('#filters-renderer > div');
        
        var scrollTop = $(this).scrollTop();
        
        if (scrollTop + $(this).innerHeight() >= this.scrollHeight) {
            way.set("dataInstances.variables.lastFilterDisplayedIndex", filters.length);
        } else if (scrollTop <= 0) {
            way.set("dataInstances.variables.firstFilterDisplayedIndex", 1);
        } else {
            var getLastDisplayedFilterElement = function (rightOffset, bottomOffset) {
              var lastDisplayedFilterElement = document.elementFromPoint(rightOffset, bottomOffset - 20);
              
              if (lastDisplayedFilterElement.parentNode.id != 'filters-renderer') {
                return getLastDisplayedFilterElement(rightOffset - 25, bottomOffset);
              } else {
                return lastDisplayedFilterElement;
              }
              
            }
            var offsets = document.getElementById('filters-renderer-container').getBoundingClientRect();
            var topOffset = offsets.top;
            var leftOffset = offsets.left;
            var rightOffset = offsets.right;
            var bottomOffset = offsets.bottom;
            var firstDisplayedFilterElement = document.elementFromPoint(leftOffset, topOffset + 17);
            var lastDisplayedFilterElement = getLastDisplayedFilterElement(rightOffset, bottomOffset);
            
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
            
            // for(var i = 0; i < displayedFiltersNumber; i++) {
            //     var currentFormControl = filterFormControls[i];
            //     var currentFilterElementTopOffset = currentFormControl.offsetTop;
            //     var currentFilterElementOffset = currentFilterElementTopOffset + currentFormControl.clientHeight;
                
            //     if ((currentFilterElementTopOffset + incrementingValue) < containerScrollTop) {
            //         way.set("dataInstances.variables.firstFilterDisplayedIndex", i + 1);
            //     }
                
            //     var elem = $(currentFormControl);
                
            //     if (pageOffset < (currentFilterElementOffset - incrementingValue)) {
            //         way.set("dataInstances.variables.lastFilterDisplayedIndex", i);
                    
            //         return;
            //     } else {
            //         way.set("dataInstances.variables.lastFilterDisplayedIndex", displayedFiltersNumber);
            //     }
                
            // }            
        }        
        
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
    
    checkForNewDiv = function () {
        var mostVisibleItem = $("#filters-renderer > div:visible");
        //alert(mostVisibleItem.size());

        var lastDiv = document.querySelector("#filters-renderer > div:last-child");
        var lastDivOffset = lastDiv.offsetTop + lastDiv.clientHeight;
        var pageOffset = wrapper.scrollTop + wrapper.clientHeight;
        var filters = way.get("dataInstances.filters");
        var lastFilterDisplayedIndex = way.get("dataInstances.variables.lastFilterDisplayedIndex");
        var incrementingValue = 10;
        
        if (pageOffset > lastDivOffset - 10 && lastFilterDisplayedIndex <= filters.length) {
            for (var i = 0; i < incrementingValue; i++) {
                var filterDiv = document.createElement('div');
                filterDiv.setAttribute("class", "filter-view");
                filterDiv.innerHTML = filters[lastFilterDisplayedIndex + i]['#text'] + ' [' + filters[lastFilterDisplayedIndex + i]['frequency'] + ']';
                document.getElementById("filters-renderer").appendChild(filterDiv.cloneNode(true));
            }
            
            way.set("dataInstances.variables.lastFilterDisplayedIndex", lastFilterDisplayedIndex + incrementingValue);
            
            checkForNewDiv();
        } else if (pageOffset < lastDivOffset - 10) {
            console.log("upscroll code");
        }
    };

    $("#filters-renderer").on("click", "div", function() {
        var $this = $(this);
        
        $this.toggleClass("selected-filter-view");
        
        var filterId = this.id;
        var filterUrl = "../../modules/filters/" + filterId.replace("i-i18n", "") + ".xql";
    });
});

// var xformsValue;

// function getXFormsValue(modelId, instanceId, xpathExpr) {
  
//   function getExcludes(rootElement) {
//     xformsValue = rootElement.ownerDocument.evaluate;
//   }

//   XFormsModelElement.getInstanceDocument(modelId, instanceId, fluxProcessor.sessionKey, getExcludes);
//   //alert(xformsValue);
// }
// getXFormsValue("m-filters", "i-configuration-filters", "//*:filter[id = 'title-words']/@excludes");

// alert(xformsValue);



// function getExcludes(modelId, instanceId, xpathExpr) {
//     return new Promise(function(resolve, reject) {
//           function getExcludes(rootElement) {
//             resolve(rootElement.ownerDocument);
//           }        
      
//          XFormsModelElement.getInstanceDocument(modelId, instanceId, fluxProcessor.sessionKey, getExcludes);
//     }).then(function(result) {
//       way.set("dataInstances.variables.filterId", result);
//     });
// };

// getExcludes("m-filters", "i-configuration-filters", "//*:filter[id = 'title-words']/@excludes");




// function getExcludes(modelId, instanceId, xpathExpr) {
//     return new Promise(function(resolve, reject) {
//           function getExcludes(rootElement) {
//             resolve(rootElement.ownerDocument);
//           }        
      
//          XFormsModelElement.getInstanceDocument(modelId, instanceId, fluxProcessor.sessionKey, getExcludes);
//     }).then(function(document) {
//       var excludes = document.evaluate(xpathExpr, document, null, XPathResult.ANY_TYPE, null).iterateNext().value;
//       way.set("dataInstances.variables.filterId", excludes);
//     });
// };

// function *generator() {
//   yield getExcludes("m-filters", "i-configuration-filters", "/*/*/*[@id = 'title-words']/@excludes");
// }

// var iterator = generator();
// iterator.next();


// alert(way.get("dataInstances.variables.filterId"));
// way.set("dataInstances.variables.filterId", "empty");


// var start = performance.now();

// for (i = 0; i < 17000; ++i) {
//     var el = document.createElement("div");//Now create an element and append it.
//   el.innerHTML = i + " [" + i + "]";
//     document.getElementById("filters-renderer").appendChild(el);
// }

// var end = performance.now();
// console.log("Op. took " + (end - start) + "ms.");
