var tamboti = tamboti || {};

/**
 * Namespace function. Required by all other classes.
 */
tamboti.namespace = function (ns_string) {
    var parts = ns_string.split('.'),
		parent = tamboti,
		i;
	if (parts[0] == "tamboti") {
		parts = parts.slice(1);
	}
	
	for (i = 0; i < parts.length; i++) {
		// create a property if it doesn't exist
		if (typeof parent[parts[i]] == "undefined") {
			parent[parts[i]] = {};
		}
		parent = parent[parts[i]];
	}
	return parent;
}

tamboti.namespace("tamboti.galleries.FilmStrip");

tamboti.galleries.FilmStrip = (function () {
    
    Constr = function (viewer, container, serverURL) {
        this.viewer = viewer;
        this.container = $(container);
        this.url = serverURL;
        this.collection = null;
        
        this.images = null;
        this.current = 0;
        
        var $this = this;
        $(".next", this.viewer.container).click(function (ev) {
            ev.preventDefault();
            $this.next();
        });
        $(".previous", this.viewer.container).click(function (ev) {
            ev.preventDefault();
            $this.previous();
        });
    };
    
    Constr.prototype = {
        open: function (item, collection, fn) {
            if (this.images) {
                this.setCurrent(item);
                if(fn != null) {
                    fn();
                }
                return;
            }
            
            this.container.show();
            
            this.collection = collection;
            
            var $this = this;
            
            this.loadGallery(1, function() {
                $this.setCurrent(item);
                if(fn != null) {
                    fn();
                }
            });
        },
        
        loadGallery : function(page, fn) {

            var $this = this;
            
            $("#filmstrip-items").empty();
            
            //send width of filmstrip to server
            var width = $("#filmstrip").width();
            
            var params = { filmstripWidth: width, page: page };
            if ($this.collection) {
                params.collection = $this.collection;
            }
            $.getJSON($this.url, params, function(data) {
                
                //extract some info from the data
                var magicWidth = data.magicWidth;
                var page = data.page;
                var totalPages = data.totalPages;
                
                $this.images = data.images;
                
                //calculate the height of the filmstrip based on the number of images retrieved
                var filmstripRowHeight = 68;
                var filmstripWidth = $("#filmstrip").width();
                var filmstripHeight = filmstripRowHeight * Math.round((data.length * magicWidth) / filmstripWidth);
                
                //add the image items into the ul
                var fragment = document.createDocumentFragment();
                for (var i = 0; i < data.images.length; i++) {
                    var li = document.createElement("li");
                    var img = document.createElement("img");
                    img.src = data.images[i].src;
                    img.id = "tamboti.filmstrip." + data.images[i].item;
                    li.appendChild(img);
                    fragment.appendChild(li);
                }
                
                //set the images, and the height
                $("ul", $this.container).html(fragment).height(filmstripHeight);
                
                //add handlers for each image
                
                $("img", $this.container).click(function (ev) {
                    $this.current = $this.container.find("img").index(this);
                    $this.viewer.show($this.images[$this.current].item, $this.collection);
                });
                
                //setup the page up and page down buttons
                
                if(page <= 1) {
                    $("#film-up").hide();
                } else {
                    $("#film-up").show();
                    
                    $("#film-up").unbind('click');
                    $("#film-up").click(function(){
                        var pageNum = page - 1;
                        if(page - 1 < 1){
                            pageNum = 1;
                        }
                        galleries.filmstrip.loadGallery(pageNum, function(){
                            $this.viewer.$resize($("#viewer-image")[0], true);
                        });
                    });
                }
                
                if(page >= totalPages) {
                    $("#film-down").hide();
                } else {
                    
                    $("#film-down").show();
                   
                    $("#film-down").unbind('click');
                    $("#film-down").click(function(){
                        var pageNum = page + 1;
                        if(page + 1 > totalPages){
                            pageNum = totalPages;
                        }
                        
                        galleries.filmstrip.loadGallery(pageNum, function(){
                            $this.viewer.$resize($("#viewer-image")[0], true);
                        });
                    });
                }
                
                //invoke any post processing
                if(fn != null){
                    fn()
                }
                
            });
        },
        
        close: function () {
            this.container.hide();
            $("ul", this.container).empty();
            this.images = null;
            this.current = 0;
        },
        
        setCurrent: function (item) {
            var $this = this;
            
            function scroll(target) {
                var offset = target.offset().left;
                var scroll = $this.container.scrollLeft();
                $.log("offset = %d scroll = %d", offset, scroll);
                if (offset > $this.container.width())
                    $this.container.scrollLeft(offset);
            }
            
            for (var i = 0; i < this.images.length; i++) {
                if (this.images[i].item === item) {
                    this.current = i;
                    $.log("current = %d internal = %i", item, i);
                    this.container.find("li.highlighted").removeClass("highlighted");
                    var target = this.container.find("li:eq(" + i + ")").addClass("highlighted");
                    scroll(target);
                    return;
                }
            }
        },
        
        next: function () {
            if (this.current + 1 < this.images.length) {
                this.current = this.current + 1;
                this.viewer.show(this.images[this.current].item, this.collection, true);
            }
        },
        
        previous: function () {
            if (this.current > 0) {
                this.current = this.current - 1;
                this.viewer.show(this.images[this.current].item, this.collection, true);
            }
        },
        
        height: function () {
            return this.container.height() + 20;
        }
    };
    
    return Constr;
}());

tamboti.namespace("tamboti.galleries.Viewer");

tamboti.galleries.Viewer = (function () {

    var MAX_IMAGE_SIZE = 1024;
    
    Constr = function (container, basePath, maxSize) {
        var $this = this;
        $this.url = "gallery.xql";
        if (basePath) {
            $this.url = basePath + "/" + $this.url;
        }
        
        $this.maxImageSize = MAX_IMAGE_SIZE;
        if (maxSize) {
            $this.maxImageSize = maxSize;
        }
        
        // current item
        $this.item = -1;
        // top level container
        $this.container = $(container);
        // the image view
        $this.view = $(".view", container);
        $this.imageContainer = $(".image", $this.view);
        $this.img = $(".image img.content", $this.view);
        $this.heading = $("h4", $this.view);
        $this.heading.attr("id", "viewer-image-title");
        $this.indicator = new Image();
        $this.indicator.src = "theme/images/ajax-loader.gif";
        $this.filmstrip = new tamboti.galleries.FilmStrip($this, $("#filmstrip"), $this.url);
        
        $(document).ready(function() {
            $(document.body).append('<div id="tamboti-galleries-overlay" class="overlay"></div>');
            $("#tamboti-galleries-overlay").click(function () {
                $this.hide();
            });
            $(".close", $this.view).click(function (ev) {
                ev.preventDefault();
                $this.hide();
            });
        });
        
        $this.view.hide();
        $this.heading.empty().toggle(false);
        $this.heading.css("max-width", Math.ceil($(window).height() / 2));
        $this.imageContainer.css({
            width: "200px",
            height: "200px"
        });
        $this.$setPosition(200, 200);
        
        $(".show-metadata", $this.container).click(function (ev) {
            ev.preventDefault();
            
            $this.getMetadata();
        });
        $(".metadata .close", $this.container).click(function (ev) {
            ev.preventDefault();
            $(".metadata").hide();
        });
    };
    
    Constr.prototype = {
        open: function () {
            $("#tamboti-galleries-overlay").show();
            this.view.show();
            $(".show-metadata", this.container).show();
        },
        
        show: function (num, collection) {
            var $this = this;
            $.log("[tamboti.galleries.Viewer] Loading item %d from collection ", num, collection);
            
            var params = { item: num };
            if (collection) {
                params.collection = collection;
            }
            $this.img.fadeOut(200, function () {
                $.getJSON($this.url, params, function (data) {
                    $this.item = num;
                    $this.heading.html(data.title);
                    $this.heading.toggle(true);
                    var src = data.src + "?s=" + $this.maxImageSize;
                    var image = new Image();
                    $(image).load(function () {
                        $this.img.attr("id", "viewer-image");
                        $this.filmstrip.open(num, collection, function() {
                            $this.img.attr("src", src);
                            $this.$resize(image, true);
                        });
                    });
                    image.src = src;
                });
            });
        },
        
        hide: function () {
            var $this = this;
            this.heading.empty().toggle(false);
            $(".metadata", this.container).hide();
            $(".show-metadata", this.container).hide();
            $this.img.fadeOut(100, function () {
                $this.img.attr("src", $this.indicator.src);
                $this.filmstrip.close(300);
                $this.imageContainer.animate({
                        width: "200px",
                        height: "200px"
                    }, { 
                        duration: 300, 
                        complete: function() {
                        $this.$setPosition(200, 200);
                        $this.view.fadeOut(200, function() {
                            $("#tamboti-galleries-overlay").fadeOut(300);
                        });
                        }
                    }
                );
            });
        },
        
        $resize: function (image, anim) {
            var $this = this;
            var extraHeight = $this.heading.outerHeight() + $this.filmstrip.height();
            
            var maxWidth = $(window).width() - 72; // border: 16 * 2 + margin: 20 * 2
            var maxHeight = $(window).height() - extraHeight - 72;
            
            var w = image.width;
            var h = image.height;
            
            if (h > maxHeight || w > maxWidth) {
                var aspectRatio;
                if(w >= h) {
                    //scale height
                    aspectRatio = h / w;
                } else {
                    //scale width
                    aspectRatio = w / h;
                }
            
                if(maxWidth >= maxHeight) {
                    //scale into width
                    h = maxHeight;
                    w = maxWidth * aspectRatio;
                } else {
                    //scale into height
                    w = maxWidth;
                    h = maxHeight * aspectRatio;
                }
            }
            $.log("window=(" + $(window).width() + "," + $(window).height() + ") max=(" + 
                maxWidth + "," + maxHeight +") new=(" + w + "," + h + ")");
            
            this.$setPosition(h + extraHeight + 32, w + 32);
            
            if (anim) {
                this.imageContainer.animate({
                    width: Math.round(w) + "px",
                    height: Math.round(h) + "px"
                }, {
                    duration: 400,
                    complete: function() {
                        $this.img.fadeIn("slow");
                    }
                });
            } else {
                this.imageContainer.css({
                    width: Math.round(w) + "px",
                    heigth: Math.round(h) + "px"
                });
            }
        },
        
        $setPosition: function (height, width) {
            var viewportHeight = $(window).height();
            var viewportWidth = $(window).width();
            var top = (viewportHeight - height) / 2;
            var left = (viewportWidth - width) / 2;
            $(this.view).animate({
                top: top + "px",
                left: left + "px",
                width: width + "px"
            },
            {
                duration: 500
            });
        },
        
        getMetadata: function () {
            if (this.item < 0)
                return;
            
            var $this = this;
            $.ajax({
                url: "session.xql",
                data: { mode: "ajax", start: $this.item, count: 1 },
                dataType: "html",
                type: "POST",
                success: function (data) {
                    $(".metadata", $this.container).show(400);
                    $(".metadata-content", $this.container).html(data);
                }
            });
        }
    };
    
    return Constr;
}());