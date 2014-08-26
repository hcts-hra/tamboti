(function($) {

    /**
     * jQuery pagination plugin. Used by the jquery.xql XQuery library.
     * The passed URL should return an HTML table with one row for each
     * record to display. Each row should have two or more columns: the first one
     * contains the record number, the remaining columns the data to be displayed.
     *
     * @param url the URL to call to retrieve a page.
     * @param opts option object to configure the plugin.
     */
    $.fn.pagination = function(method) {
        // Default options
        var defaults = {
            url: null,
            totalItems: 0,
            itemsPerPage: 20,
            singleItemView: ".pagination-toggle",
            startParam: "start",
            countParam: "count",
            navContainer: null,
            params: null,
            readyCallback: function() { },
            itemCallback: function () { }
        };
        
        // Public methods
        var methods = {
            init: function(opts) {
                
                return this.each(function() {
                    var base = this;
                    base.options = {};
                    base.currentItem = 1;
                    base.element = null;
                    
                    base.options = $.extend(defaults, opts || {});
                    if (!base.options.url) {
                        $.error("pagination plugin requires an 'url' option");
                        return;
                    }
                    if (base.options.totalItems == 1)
                        base.options.itemsPerPage = 1;
                    base.element = $(base);
                    helpers.initNavbar(base);
                    if (base.options.totalItems > 0)
                        helpers.retrievePage(base, 1);
                    
                    base.element.data("pagination", base);
                });
            },
            
            /**
             * Set or retrieve an option.
             */
            option: function (key, value) {
                var base = this.data("pagination");
                $.log("[pagination] Setting option %s = %s", key, value);
                if (value) {
                    base.options[key] = value;
                } else {
                    return base.options[key];
                }
            },
            
            /**
             * Reload the currently displayed page.
             */
            refresh: function () {
                var base = this.data("pagination");
                helpers.retrievePage(base, base.currentItem);
            }
        };
        
        // helper functions only available within the plugin.
        var helpers = {
            
            displayPage: function(base, data) {
                helpers.updateNavbar(base);
                base.element.html(data);
                if (base.options.singleItemView) {
                    $(base.options.singleItemView, base.element).click(function (ev) {
                        ev.preventDefault();
                        var nr = $(this).parent(".pagination-item").find(".pagination-number");
                        if (!nr || nr.length == 0)
                            return;
                        base.options.itemsPerPage = 1;
                        nr = parseInt(nr.text());
                        $.log("[pagination] Showing single entry: %d", nr);
                        helpers.retrievePage(base, nr);
                    });
                }
                if (base.options.readyCallback)
                    base.options.readyCallback.call(base.element, base.options);
            },
    
            initNavbar: function(base) {
                if (!base.options.navContainer) {
                    return;
                }
                var div = $(base.options.navContainer);
                $(".pagination-first", div).click(function () {
                    if (base.currentItem != 1)
                    helpers.retrievePage(base, 1);
                    return false;
                });
                $(".pagination-previous", div).click(function () {                    
                        if (base.options.itemsPerPage == 1) {
                            if (base.currentItem - base.options.itemsPerPage >= base.options.itemsPerPage)
                            helpers.retrievePage(base, base.currentItem - base.options.itemsPerPage); }
                        else if (base.currentItem - base.options.itemsPerPage >= 0)
                            helpers.retrievePage(base, base.currentItem - base.options.itemsPerPage);
                        else 
                            helpers.retrievePage(base, 1);
                    return false;
                });
                $(".pagination-next", div).click(function () {
                    if (base.options.totalItems - (base.currentItem + base.options.itemsPerPage) >= 0)
                    helpers.retrievePage(base, base.currentItem + base.options.itemsPerPage);
                    return false;
                });
                $(".pagination-last", div).click(function () {
                    if (base.options.itemsPerPage == 1) {
                        if (base.currentItem != base.options.totalItems)
                        helpers.retrievePage(base, base.options.totalItems); }
                    else if (base.currentItem + base.options.itemsPerPage <= base.options.totalItems)
                            helpers.retrievePage(base, base.options.totalItems);
                    return false;
                });
                if (base.options.singleItemView) {
                    $(base.options.singleItemView, div).hide().click(function (ev) {
                        ev.preventDefault();
                        base.options.itemsPerPage = 20;
                        var currentPage = Math.floor(base.currentItem / base.options.itemsPerPage);
                        var item = currentPage * base.options.itemsPerPage;
                        // if (item == 0)
                        //     item = 1;
                        item +=1;
                        helpers.retrievePage(base, item);
                    });
                }
            },
        
            updateNavbar: function(base) {
                if (!base.options.navContainer) {
                    return;
                }
                var div = $(base.options.navContainer);
                if (base.currentItem <= 1) {
                    $(".pagination-first", div).addClass("inactive");
                    $(".pagination-previous", div).addClass("inactive");
                } else {
                    $(".pagination-first", div).removeClass("inactive");
                    $(".pagination-previous", div).removeClass("inactive");
                }
                
                if (base.options.itemsPerPage == 1) {
                    $(".pagination-info", div).text('Record ' + base.currentItem);
                } else {
                    var recordSpan;
                    if (base.options.totalItems == base.currentItem)
                        recordSpan = ('Record ' + base.currentItem);
                    else if (base.options.totalItems < (base.currentItem + base.options.itemsPerPage - 1))
                        recordSpan = ('Records ' + base.currentItem + ' to ' + base.options.totalItems);
                    else
                        recordSpan = ('Records ' + base.currentItem + ' to ' + 
                            ((base.currentItem + base.options.itemsPerPage - 1)));
                    $(".pagination-info", div).text(recordSpan);
                }
        
                if (base.options.totalItems - (base.currentItem + base.options.itemsPerPage) < 0) {
                    $(".pagination-next", div).addClass("inactive");
                } else {
                    $(".pagination-next", div).removeClass("inactive");
                }
                    
                if (base.options.itemsPerPage == 1) {
                    if (base.currentItem == base.options.totalItems) {
                        $(".pagination-last", div).addClass("inactive");
                    } else {
                        $(".pagination-last", div).removeClass("inactive");
                    }
                    }
                    else if (base.currentItem + base.options.itemsPerPage > base.options.totalItems) {
                        $(".pagination-last", div).addClass("inactive");
                    } else {
                        $(".pagination-last", div).removeClass("inactive");                                   
                }
                
                if (base.options.singleItemView) {
                    if (base.options.itemsPerPage == 1) {
                        $(base.options.singleItemView, div).show();
                    } else {
                        $(base.options.singleItemView, div).hide();
                    }
                }
                return div;
            },
    
            retrievePage: function(base, start) {
                var params = {
                    start: start,
                    count: base.options.itemsPerPage
                };
                if (base.options.params) {
                    for (var option in base.options.params) {
                        params[option] = base.options.params[option];
                    }
                }
                $.log("[pagination] Retrieving page: %d from %s", start, base.options.url);
                base.element.empty();
                console.debug(base.options.url);
                $.ajax({
                    type: "GET",
                    url: base.options.url,
                    data: params,
                    dataType: "html",
                    success: function(data) { 
                        base.currentItem = start;
                        helpers.displayPage(base, data); 
                    },
                    error: function (req, status, errorThrown) {
                        alert(status);
                    }
                });
            }
        };
        
        if (methods[method]) {
            // call the respective method
            return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
        // if an object is given as method OR nothing is given as argument
        } else if (typeof method === 'object' || !method) {
            // call the initialization method
            return methods.init.apply(this, arguments);
        // otherwise
        } else {
            // trigger an error
            $.error( 'Method "' +  method + '" does not exist in pagination plugin!');
        }
    };
})(jQuery);

(function($) {
    $.fn.repeat = function(trigger, opts) {
        var options = $.extend({
            deleteTrigger: null,
            onReady: function() { }
        }, opts || {});
        var container = this;
        var selected = null;

        $('.repeat', container).each(function() {
            addEvent($(this));
        });       
        $(trigger).click(function(ev) {
        	ev.preventDefault();
            var last = $('.repeat:last', container);
            var newNode = last.clone();
            last.after(newNode);
            newNode.each(function () {
                $(':input', this).each(function() {
                    var $input = $(this);
                    var name = $input.attr('name');
                    var n = /(.*)(\d+)$/.exec(name);
                    $input.attr('name', n[1] + (Number(n[2]) + 1));
                    if (this.value != '') {
                        this.value = '';
                    }
                    if ($input.attr('class') == "delete-search-field-button") {
                        $input.click(function(ev) {
                            ev.preventDefault();
                            $(this).parent().parent().remove();
                            return false;
                        });                         
                    }
                    if ($input.attr('class') == "ui-autocomplete-input") {
                        $input.bind("keyup keypress", function(e) {
                            var code = e.keyCode || e.which; 
                            if (code  == 13) {
                              e.preventDefault();                  
                              $('#advanced-search').submit();
                      	    return false;
                      	  }
                        });                        
                    }                    
                });
            });
            addEvent(newNode);
            $('.repeat', container).removeClass('repeat-selected');
            options.onReady.call(newNode);
            
            last = $('.repeat:last', container);
            $("td.operator select option:first-child", last).prop("selected", "selected");
            $("td.search-field select option:first-child", last).prop("selected", "selected");            
        });
        if (options.deleteTrigger != null)
            $(options.deleteTrigger).click(function(ev) {
                deleteCurrent();
                ev.preventDefault();
            });
        function addEvent(repeat) {
            repeat.click(function() {
                selected = repeat;
                $('.repeat', container).removeClass('repeat-selected');
                repeat.addClass('repeat-selected');
            });
        }

        function deleteCurrent() {
            if (selected) {
                selected.remove();
            }
        }
    }
})(jQuery);

(function($) {
    $.fn.form = function(opts) {
    	var options = $.extend({
            done: function() { },
            cancel: function () { }
        }, opts || {});
    	var container = this;
    	var pages = container.find("fieldset");
    	var currentPage = 0;
    	
    	// append back and next buttons to container
    	var panel = document.createElement("div");
    	panel.className = "eXist_wizard_buttons";
    	panel.style.position = "absolute";
    	panel.style.bottom = "0";
    	panel.style.right = "0";
    	
    	var btn = document.createElement("button");
    	btn.className = "eXist_wizard_back";
    	btn.appendChild(document.createTextNode("Back"));
    	panel.appendChild(btn);
    	
    	btn = document.createElement("button");
    	btn.className = "eXist_wizard_next";
    	btn.appendChild(document.createTextNode("Next"));
    	panel.appendChild(btn);
    	
    	btn = document.createElement("button");
    	btn.className = "eXist_wizard_cancel";
    	btn.appendChild(document.createTextNode("Cancel"));
    	panel.appendChild(btn);
    	
    	btn = document.createElement("button");
    	btn.className = "eXist_wizard_done";
    	btn.appendChild(document.createTextNode("Done"));
    	panel.appendChild(btn);
    	container.append(panel);
    	
    	$("button", container).button();
    	
    	for (var i = 1; i < pages.length; i++) {
    		$(pages[i]).css("display", "none");
    	}
    	$(".eXist_wizard_back", container).button("disable");
    	
    	$(".eXist_wizard_next", container).click(function () {
    		if (currentPage == pages.length - 1)
    			return;
    		$(pages[currentPage]).css("display", "none");
    		$(pages[++currentPage]).css("display", "");
    		if (currentPage == 1) {
    			$(".eXist_wizard_back", container).button("enable");
    		} else if (currentPage == pages.length - 1) {
    			$(this).button("disable");
    		}
    	});
    	$(".eXist_wizard_back", container).click(function () {
    		if (currentPage == 0)
    			return;
    		if (currentPage == pages.length - 1) {
    			$(".eXist_wizard_next", container).button("enable");
    		}
    		$(pages[currentPage]).css("display", "none");
    		$(pages[--currentPage]).css("display", "");
    		if (currentPage == 0) {
    			$(this).button("disable");
    		}
    	});
    	$(".eXist_wizard_cancel", container).click(function () {
    		// Cancel.
    		options.cancel.call(container);
    	});
    	$(".eXist_wizard_done", container).click(function () {
    		options.done.call(container);
    	});
    	return container;
    }
})(jQuery);

(function($) {
    $.each(['log','warn'], function(i,fn) {
        $[fn] = function() {
            if (!window.console) return;
            var p = [], a = arguments;
            for (var i=0; i<a.length; i++)
                p.push(a[i]) && (i+1<a.length) && p.push(' ');
            Function.prototype.bind.call(console[fn], console)
                .apply(this, p);
        };
        
        $.fn[fn] = function() {
            var p = [this], a = arguments;
            for (var i=0; i<a.length; i++) p.push(a[i]);
            $[fn].apply(this, p);
            return this;
        };
    });
    $.assert = function() {
        window.console
            && Function.prototype.bind.call(console.assert, console)
               .apply(console, arguments);
    };
})(jQuery);


/* Debug and logging functions */
/*
(function($) {
    $.log = function() {
//      if (typeof console == "undefined" || typeof console.log == "undefined") {
//          console.log( Array.prototype.slice.call(arguments) );
        if(window.console && window.console.log) {
            console.log.apply(window.console,arguments)
        }
    };
    $.fn.log = function() {
        $.log(this);
        return this;
    }
  
})(jQuery);
  */