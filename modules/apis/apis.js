tamboti.apis = {};

tamboti.apis._loadPaginator = function(hitCounts, navContainer, initialiseNavbar) {
    $("#result-items-count").text(hitCounts);
    tamboti.totalSearchResultOptions = hitCounts;
    
    if (hitCounts > 0) {
        $("#results").pagination({
            url: "../../api/resources",
            totalItems: hitCounts,
            itemsPerPage: tamboti.itemsPerPage,
            navContainer: navContainer,
            readyCallback: resultsLoaded,
            params: { "mode": "list", "initialiseNavbar": initialiseNavbar }
        });
    } else {
        $("#results").html("No records found.");
    }
};

// tamboti.apis.collectionSearch has to be removed when the paginator will be a standalone component
tamboti.apis.collectionSearch = function() {
    $("#results").html("Searching ...");
    const collection = "collection=" + document.querySelector("#simple-search-collection-path").value;
    const queryString = "?" + collection;
    
    $.ajax({
        url: "../../api/search/collection" + queryString,
        dataType: "text",
        type: "GET",
        success: function (data) {
        	tamboti.apis._loadPaginator(data, "#results-head .navbar", true);
        }
    });
};

tamboti.apis.simpleSearch = function() {
    $("#results").html("Searching ...");
    const q = "q=" + document.querySelector("#simple-search-tab input[name='input1']").value;
    const collection = "collection=" + document.querySelector("#simple-search-collection-path").value;
    const queryString = "?" + q + "&" + collection;
    
    $.ajax({
        url: "../../api/search/simple" + queryString,
        dataType: "text",
        type: "GET",
        success: function (data) {
        	tamboti.apis._loadPaginator(data, "#results-head .navbar", true);
        }
    });
};

tamboti.apis.advancedSearch = function() {
    var advancedSearchForm = $("#advanced-search-tab");
    var data = {
        "format": $("select[name='format']", advancedSearchForm).val(),
        "default-operator": $("select[name='default-operator']", advancedSearchForm).val(),
        "sort": $("select[name='sort']", advancedSearchForm).val(),
        "sort-direction": $("select[name='sort-direction']", advancedSearchForm).val(),
        "collection-tree": $("input[name='collection-tree']", advancedSearchForm).val(),
        "collection": $("advanced-search-collection-path").val(),
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
        url: "../../api/search/advanced/",
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
        url: "../../api/search/advanced/",
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
            "collection": $("#advanced-search-collection-path").val(),
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
