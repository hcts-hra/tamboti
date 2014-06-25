$(function() {
    tamboti.apis = {};
    
    // tamboti.apis.initialSearch has to be removed when the paginator will be a standalone component
    tamboti.apis.initialSearch = function() {
        $("#results").html("Searching ...");
        $.ajax({
            url: "index.html",
            data: {
                "input1": $("#simple-search-form input[name='input1']").val(),
                "render-collection-path": $("#simple-search-form input[name='render-collection-path']").val(),
                "sort": $("#simple-search-form select[name='sort']").val(),
                "field1": $("#simple-search-form input[name='field1']").val(),
                "query-tabs": $("#simple-search-form input[name='query-tabs']").val(),
                "collection-tree": $("#simple-search-form input[name='collection-tree']").val(),
                "collection": $("#simple-search-form input[name='collection']").val()
            },
            dataType: "html",
            type: "POST",
            success: function (data) {
            	tamboti.apis._loadPaginator(data, "#results-head .navbar", true);
            }
        });
    };
    
    tamboti.apis.simpleSearch = function() {
        $("#results").html("Searching ...");
        $.ajax({
            url: "index.html",
            data: {
                "input1": $("#simple-search-form input[name='input1']").val(),
                "render-collection-path": $("#simple-search-form input[name='render-collection-path']").val(),
                "sort": $("#simple-search-form select[name='sort']").val(),
                "field1": $("#simple-search-form input[name='field1']").val(),
                "query-tabs": $("#simple-search-form input[name='query-tabs']").val(),
                "collection-tree": $("#simple-search-form input[name='collection-tree']").val(),
                "collection": $("#simple-search-form input[name='collection']").val()
            },
            dataType: "html",
            type: "POST",
            success: function (data) {
            	tamboti.apis._loadPaginator(data, "#results-head .navbar", false);
            }
        });
    };
    
    tamboti.apis.advancedSearch = function() {
        $("#results").html("Searching ...");        
        $.ajax({
            url: "index.html",
            data: {
                "format": $("#advanced-search-form select[name='format']").val(),
                "default-operator": $("#advanced-search-form select[name='default-operator']").val(),
                "operator1": $("#advanced-search-form select[name='operator1']").val(),
                "input1": $("#advanced-search-form input[name='input1']").val(),
                "field1": $("#advanced-search-form input[name='field1']").val(),
                "render-collection-path": $("#advanced-search-form input[name='render-collection-path']").val(),
                "sort": $("#advanced-search-form select[name='sort']").val(),
                "sort-direction": $("#advanced-search-form select[name='sort-direction']").val(),
                "query-tabs": $("#advanced-search-form input[name='query-tabs']").val(),
                "collection-tree": $("#advanced-search-form input[name='collection-tree']").val(),
                "collection": $("#advanced-search-form input[name='collection']").val()
            },
            dataType: "html",
            type: "POST",
            success: function (data) {
            	tamboti.apis._loadPaginator(data, "#results-head .navbar", false);
            }
        });
    };
    
    tamboti.apis._loadPaginator = function(data, navContainer, initialiseNavbar) {
        var hitCounts = $(data).find("#results-head .hit-count").first().text();
        $("#results-head .hit-count").text(hitCounts);
        tamboti.ddlcb.dropDownListCheckbox.setMaxNumberOfOptions(hitCounts);
        $("#last-collection-queried").text(" found in " + $("#simple-search-form input[name='render-collection-path']").val());
        
        if (hitCounts > 0) {
            $("#results").pagination({
                url: "retrieve",
                totalItems: $("#results-head .hit-count").text(),
                itemsPerPage: 10,
                navContainer: navContainer,
                readyCallback: resultsLoaded,
                params: { "mode": "list", "initialiseNavbar": initialiseNavbar }
            });
        } else {
            $("#results").html("No records found.");
        }
    };
});