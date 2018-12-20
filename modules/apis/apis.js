tamboti = {};
tamboti.apis = {};
tamboti.currentCollection = "/data/commons/Cluster Publications";

// tamboti.apis.initialSearch has to be removed when the paginator will be a standalone component
tamboti.apis.initialSearch = function() {
    $("#results").html("Searching ...");

    var advancedSearchForm = $("#advanced-search-form");
    var data = {
        "format": $("select[name='format']", advancedSearchForm).val(),
        "default-operator": $("select[name='default-operator']", advancedSearchForm).val(),
        "sort": "Author",
        "sort-direction": "descending",
        "query-tabs": $("input[name='query-tabs']", advancedSearchForm).val(),
        "collection-tree": $("input[name='collection-tree']", advancedSearchForm).val(),
        "collection": tamboti.currentCollection,
        "filter": $("input[name='filter']", advancedSearchForm).val(),
        "value": $("input[name='value']", advancedSearchForm).val(),
        "history": $("input[name='history']", advancedSearchForm).val(),
        "search-field": $.getParameter('search-field')
    }
    var inputs = $("input[name ^= 'input']", advancedSearchForm);
    $.each(inputs, function(key, value) {
        var $this = $(this);
        data[$this.prop('name')] = $this.val();
    });
    var fields = $("select[name ^= 'field']", advancedSearchForm);
    $.each(fields, function(key, value) {
        var $this = $(this);
        data[$this.prop('name')] = $this.val();
    });
    var operators = $("select[name ^= 'operator']", advancedSearchForm);
    $.each(operators, function(key, value) {
        var $this = $(this);
        data[$this.prop('name')] = $this.val();
    }); 

    $.ajax({
        url: "search/advanced/",
        data: JSON.stringify(data),
        contentType: "application/json",
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
        url: "search/simple/",
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
    var advancedSearchForm = $("#advanced-search-form");
    var data = {
        "format": $("select[name='format']", advancedSearchForm).val(),
        "default-operator": $("select[name='default-operator']", advancedSearchForm).val(),
        "sort": $("select[name='sort']", advancedSearchForm).val(),
        "sort-direction": $("select[name='sort-direction']", advancedSearchForm).val(),
        "query-tabs": $("input[name='query-tabs']", advancedSearchForm).val(),
        "collection-tree": $("input[name='collection-tree']", advancedSearchForm).val(),
        "collection": $("input[name='collection']", advancedSearchForm).val(),
        "filter": $("input[name='filter']", advancedSearchForm).val(),
        "value": $("input[name='value']", advancedSearchForm).val(),
        "history": $("input[name='history']", advancedSearchForm).val(),
        "search-field": $.getParameter('search-field')
    }
    
    var inputs = $("input[name ^= 'input']", advancedSearchForm);
    $.each(inputs, function(key, value) {
        var $this = $(this);
        data[$this.prop('name')] = $this.val();
    });
    var fields = $("select[name ^= 'field']", advancedSearchForm);
    $.each(fields, function(key, value) {
        var $this = $(this);
        data[$this.prop('name')] = $this.val();
    });
    var operators = $("select[name ^= 'operator']", advancedSearchForm);
    $.each(operators, function(key, value) {
        var $this = $(this);
        data[$this.prop('name')] = $this.val();
    });        
    
    $("#results").html("Searching ...");        
    $.ajax({
        url: "search/advanced/",
        data: JSON.stringify(data),
        contentType: "application/json",
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
        url: "search/advanced/",
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
            "value": unescape(data['value']),
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
