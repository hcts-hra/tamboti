$(function() {
    
    function tog(v) {
        return v?'addClass':'removeClass';
    }

    if (!tamboti.browser.chrome) {
        $(document).on('input', '.clearable', function() {
            $(this)[tog(this.value)]('x');
        }).on('mousemove', '.x', function( e ){
            $(this)[tog(this.offsetWidth-18 < e.clientX-this.getBoundingClientRect().left)]('onX');
        }).on('click', '.onX', function() {
            $(this).removeClass('x onX').val('').change();
        });        
    }    
    
    tamboti.utils.resetSimpleSearchForm = function() {
        var form = $('#simple-search-form');
        $("input[name='input1']", form).val('');
        $("select[name = 'sort'] option:first-child", form).each(function() {
            $(this).prop("selected", "selected");
        });
    };    
    
    tamboti.utils.resetAdvancedSearchForm = function() {
        var form = $('#advanced-search-form > form');
        $("table", form).find("tr.repeat:gt(0)").remove();
        $("td.operator select option:first-child", form).each(function() {
            $(this).prop("selected", "selected");
        });
        $("td.search-term input.ui-autocomplete-input", form).each(function() {
            $(this).val('');
        });
        $("td.search-field select option:first-child", form).each(function() {
            $(this).prop("selected", "selected");
        });    
    };
    
    tamboti.apis.displayPersonalList = function() {
        $("#results").html("Searching ...");
        $.ajax({
            url: "search/",
            data: {
                "mylist": true
            },
            dataType: "html",
            type: "POST",
            success: function (data) {
            	tamboti.apis._loadPaginator(data, "#results-head .navbar", false);
                fluxProcessor.dispatchEventType("main-content", "set-number-of-all-options", {
                    "number-of-all-options": $("#result-items-count").text()
                });            	
            }
        });
    };
    
    $("#query-tabs").tabs({
        beforeActivate: function(ev, ui) {
            if (ui.newTab.index() == 2) {
               $("#query-history").load("../../modules/search/history/");
            }
            if (ui.newTab.index() == 3) {
                $('#personal-list-size').load('user.xql', {action: 'count'});
            }    
        },
        active: 0
    });

	$("#search-help").load("../../includes/search-help.xq");
    $("#about-tamboti").load("../../includes/about-tamboti.xq");
    $("#cluster-collections").load("../../includes/tamboti-collections.xq");
    
    $("#simple-search-form input[name = 'input1']").autocomplete({
        source: function(request, response) {
            var data = { term: request.term };
            autocompleteCallback($("#simple-search-form input[name = 'input1']"), data);
            $.ajax({
                url: "autocomplete.xql",
                dataType: "json",
   				data: data,
                success: function(data) {
                    response(data);
                }});
        },
        minLength: 3,
        delay: 700
    });
    
    $("#advanced-search-form input[name = 'input1']").autocomplete({
        source: function(request, response) {
            var data = { term: request.term };
            autocompleteCallback($("#advanced-search-form input[name = 'input1']"), data);
            $.ajax({
                url: "autocomplete.xql",
                dataType: "json",
   				data: data,
                success: function(data) {
                    response(data);
                }});
        },
        minLength: 3,
        delay: 700
    });            
    
    $('.search-form').repeat('#add-field', {
        deleteTrigger: '',
        onReady: repeatCallback}
    );
    
    $("#simple-search-form-submit-button").click(function() {
        tamboti.apis.simpleSearch();
    }); 
    
    $("#advanced-search-form-submit-button").click(function() {
        tamboti.apis.advancedSearch();
    });    
});
