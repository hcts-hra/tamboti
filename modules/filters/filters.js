$(document).ready(function() {
    $("#filters2-navigation").on("click", "a", function() {
        
        alert(this.id)
    });
    
    $('#example').DataTable({
        "ajax": {
            "url": "../filters/names.xql",
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
        "deferLoading": 0,
        "deferRender":    true,
        "scrollY":        "300px",
        "scrollX": false,
        "scrollCollapse": true,
        "paging": false,
        "sorting": false,
        "bInfo" : false
    });
    } );
