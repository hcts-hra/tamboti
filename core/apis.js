$(function() {
    tamboti.apis = {};
    
    // tamboti.apis.initialSearch has to be removed when the paginator will be a standalone component
    tamboti.apis.initialSearch = function() {
        $("#results").html("Searching ...");
        $.ajax({
            url: "search/",
            data: {
                "input1": $("#simple-search-form input[name='input1']").val(),
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
            	tamboti.totalSearchResultOptions = $("#result-items-count").text();
            }
        });
    };
    
    tamboti.apis.simpleSearch = function() {
        $("#results").html("Searching ...");
        $.ajax({
            url: "search/",
            data: {
                "input1": $("#simple-search-form input[name='input1']").val(),
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
                tamboti.totalSearchResultOptions = $("#result-items-count").text();            	
            }
        });
    };
    
    tamboti.apis.advancedSearch = function() {
        $("#results").html("Searching ...");        
        $.ajax({
            url: "search/",
            data: {
                "format": $("#advanced-search-form select[name='format']").val(),
                "default-operator": $("#advanced-search-form select[name='default-operator']").val(),
                "operator1": $("#advanced-search-form select[name='operator1']").val(),
                "input1": $("#advanced-search-form input[name='input1']").val(),
                "field1": $("#advanced-search-form input[name='field1']").val(),
                "sort": $("#advanced-search-form select[name='sort']").val(),
                "sort-direction": $("#advanced-search-form select[name='sort-direction']").val(),
                "query-tabs": $("#advanced-search-form input[name='query-tabs']").val(),
                "collection-tree": $("#advanced-search-form input[name='collection-tree']").val(),
                "collection": $("#advanced-search-form input[name='collection']").val(),
                "filter": $("#advanced-search-form input[name='filter']").val(),
                "value": $("#advanced-search-form input[name='value']").val(),
                "history": $("#advanced-search-form input[name='history']").val(),
                "search-field": $.getParameter('search-field')
            },
            dataType: "html",
            type: "POST",
            success: function (data) {
            	tamboti.apis._loadPaginator(data, "#results-head .navbar", false);
            	tamboti.totalSearchResultOptions = $("#result-items-count").text();
            }
        });
    };
    
    tamboti.apis.advancedSearchWithData = function(data) {
    	$("#query-tabs").tabs("option", "active", 1);
    	tamboti.utils.resetAdvancedSearchForm();
        var collection = data['collection'];

        $.ajax({
            url: "search/",
            data: {
                "format": 'MODS or TEI or VRA or Wiki',
                "default-operator": data['default-operator'],
                "operator1": 'and',
                "input1": data['input1'],
                "field1": data['field1'],
                "sort": 'Score',
                "sort-direction": 'descending',
                "query-tabs": data['query-tabs'],
                "collection-tree": 'hidden',
                "collection": $("#advanced-search-form input[name='collection']").val(),
                "filter": data['filter'],
                "value": data['value'],
                "history": data['history'],
                "search-field": "ID"
            },
            dataType: "html",
            type: "POST",
            success: function (data) {
            	tamboti.apis._loadPaginator(data, "#results-head .navbar", false);
            	tamboti.totalSearchResultOptions = $("#result-items-count").text();
            }
        });        
    };
    
    tamboti.apis._loadPaginator = function(data, navContainer, initialiseNavbar) {
        var hitCounts = $(data).data("result-count");
        $("#result-items-count").text(hitCounts);
        
        if (hitCounts > 0) {
            $("#results").pagination({
                url: "retrieve",
                totalItems: $("#result-items-count").text(),
                itemsPerPage: 20,
                navContainer: navContainer,
                readyCallback: resultsLoaded,
                params: { "mode": "list", "initialiseNavbar": initialiseNavbar }
            });
        } else {
            $("#results").html("No records found.");
        }
    };
});
