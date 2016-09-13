tamboti.filters = {};

tamboti.filters.filterName = "";

tamboti.filters.tableDefinition =
{
        "ajax": {
            "url": "../filters/empty.xql",
            "dataSrc":
                function (data) {
                    var data = data.sort();
                    var dataLength = data.length;
                    var dataLengthPadding = 5 - dataLength % 5;
                    while (dataLengthPadding > 0) {
                        data.push("");
                        dataLengthPadding = dataLengthPadding - 1;
                    }
                    
                    var processedData = [];
                    
                    while (data.length > 0) {
                        processedData.push(data.splice(0, 5));
                    }
                    
                    $("#" + tamboti.filters.filterId + " > img").hide();
                    
                    return processedData;
                }
        },
        "columns": [
            { "width": "20%"},
            { "width": "20%"},
            { "width": "20%"},
            { "width": "20%"},
            { "width": "20%"}
        ],
        "columnDefs": [
                {
                    "render": function ( data, type, row ) {
                        return "<a href='#' onclick='tamboti.apis.advancedSearchWithData({&quot;filter&quot; : &quot;Name&quot;, &quot;value&quot; : &quot;" + escape(data) + "&quot;, &quot;query-tabs&quot; : &quot;advanced-search-form&quot;, &quot;default-operator&quot; : &quot;and&quot;, &quot;collection&quot; : &quot;" + tamboti.currentCollection + "&quot;})'>" + data + "</a>";
                    },
                    "targets": "_all"
                }
        ],
        "deferRender":    true,
        "scrollY": "300px",
        "scrollX": false,
        "scrollCollapse": true,
        "paging": false,
        "sorting": false,
        "bInfo" : false
    };

$(document).ready(function() {
    $("#filters2-navigation").on("click", "a", function() {
        var $this = $(this);
        var filterId = this.id;
        tamboti.filters.filterId = filterId;
        var filterName = filterId.replace("-filter", "");
        
        $("img", $this).show();
        
        tamboti.filters.table.ajax.url("../filters/" + filterName + ".xql");
        tamboti.filters.table.load();
    });
    
    tamboti.filters.table = $('#example').DataTable(tamboti.filters.tableDefinition);
});
