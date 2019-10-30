jQuery.support.cors = true;

var TambotiColViewer = {
    options: {
        start: 1,
        limit: 20,
        tambotiURL: 'http://localhost:8080/exist/apps/tamboti',
        tambotiService: '/frameworks/mods-hra/get-collection-mods.xq',
        tambotiImageService: 'http://localhost:8080/exist/apps/tamboti/modules/display/image.xql', 
        collection: '/db/resources/commons/Cluster Publications',
        embedVRA: false,
        vraPos: 1
    },

    initResults: function(limit, collection){
        this.tableHeading(); //add the table header 
        if(collection)
            this.options.collection = collection;
            
        // register onclick-handler for dropdowns etc
        $(".tamboti-years").bind("change", function(){
            TambotiColViewer.setFilterYear(this.value);
        });
    
        $(".tamboti-genres").bind("change", function(){
            TambotiColViewer.setFilterGenre(this.value);
        });
        $(".tamboti-limit").bind("change", function(){
            TambotiColViewer.setLimit(this.value);
        });
        
        // Only fill name filter dropdowns if existing
        $familyNameFilter = $(".tamboti-familyName");
        if($familyNameFilter){
            this.updateDistinctFamilyNames();
            // register event listener
            $familyNameFilter.bind("change", function(){
                TambotiColViewer.updateDistinctGivenNames($(this).attr('value'));
            });
        }

        $givenNameFilter = $(".tamboti-givenName");
        if($givenNameFilter){
            this.updateDistinctGivenNames();
            $givenNameFilter.bind("change", function(){
                TambotiColViewer.updateResults();
            });
        }
        
        $nameFilterReset = $(".taboti-names-reset");
        if($nameFilterReset){
            $nameFilterReset.bind("click", function(){
                if($familyNameFilter){
                    $firstOption = $familyNameFilter.find("option");
                    $($firstOption[0]).prop("selected", true);
                    TambotiColViewer.updateDistinctFamilyNames();
                }
                if($givenNameFilter)
                    $firstOption = $givenNameFilter.find("option");
                    $($firstOption[0]).prop("selected", true);
                    TambotiColViewer.updateDistinctGivenNames();
                TambotiColViewer.updateResults();
            });
        }
        
        
        $("[sort]").click(function() {
            var colorSelected = "#000000";
            $("[sort]").css("color", "");
            
            var clicked = this.attributes.sort.value.split("-");
            var sort = clicked[0];
            var desc = clicked[1]?"desc":"";
            switch(sort){
                case "title":
                    $('#tamboti-collection').attr('order-by', 'title');
                    break;
                case "year":
                    $('#tamboti-collection').attr('order-by', 'year');
                    break;
            }
            if (desc) 
                $('[sort="' + sort + '-desc"]').css("color", colorSelected);
            else 
                $('[sort="' + sort + '"]').css("color", colorSelected);
    
            $('#tamboti-collection').attr('desc', desc);
            $('#tamboti-collection').attr('start', 1);
            
            TambotiColViewer.updateResults();
        });
        this.updateResults();

    },
    
    updateDistinctFamilyNames: function(givenName){
        var familyNameStartingWith = $('#tamboti-collection').attr('family-name-starting-with');
        $.ajax({
            crossDomain: true,
            url: TambotiColViewer.options.tambotiURL + TambotiColViewer.options.tambotiService,
            data: {
                collection: TambotiColViewer.options.collection,
                action : 'distinctFamilyNames',
                familyNameStartingWith: familyNameStartingWith,
                givenName: givenName
            },
            type: "POST",
            dataType: "json",
            success: function( json ) {
                $familyNameDropdown = $(".tamboti-familyName");
                $familyNameDropdown.empty();
                $familyNameDropdown.append('<option value="">All</option>');
                for(var i in json.name)
                    $familyNameDropdown.append('<option value="' + json.name[i] + '">' + json.name[i] + '</option>');
                TambotiColViewer.setPage(1);
            },
            error: function( xhr, status, errorThrown ) {
                $('#results').empty();
                var html = '\
                    <tr>\
                        <td colspan="3" style="text-align:center;">\
                            Error loading data.\
                        </td>\
                    </tr>';
                $('#results').append(html);
                if(typeof console !== "undefined"){
                    console.log( "Error: " + errorThrown );
                    console.log( "Status: " + status );
                    // console.dir( xhr );
                }
            }
        });
    },

    updateDistinctGivenNames: function(familyName){
        var familyNameStartingWith = $('#tamboti-collection').attr('family-name-starting-with');
        $.ajax({
            crossDomain: true,
            url: TambotiColViewer.options.tambotiURL + TambotiColViewer.options.tambotiService,
            data: {
                collection: TambotiColViewer.options.collection,
                action : 'distinctGivenNames', 
                familyNameStartingWith: familyNameStartingWith,
                familyName: familyName
            },
            type: "POST",
            dataType: "json",
            success: function( json ) {
                $givenNameDropdown = $(".tamboti-givenName");
                $givenNameDropdown.empty();
                $givenNameDropdown.append('<option value="">All</option>');
                for(var i in json.name)
                    $givenNameDropdown.append('<option value="' + json.name[i] + '">' + json.name[i] + '</option>');
                TambotiColViewer.setPage(1);
                TambotiColViewer.updateResults();

            },
            error: function( xhr, status, errorThrown ) {
                $('#results').empty();
                var html = '\
                    <tr>\
                        <td colspan="3" style="text-align:center;">\
                            Error loading data.\
                        </td>\
                    </tr>';
                $('#results').append(html);
                if(typeof console !== "undefined"){
                    console.log( "Error: " + errorThrown );
                    console.log( "Status: " + status );
                    // console.dir( xhr );
                }
            }
        });

    },

    
    tableHeading: function(){
        $html = $('\
                <tr>\
                    <th class="first">\
                        <p>Author</p>\
                    </th>\
                    <th>\
                        <p>Title</p>\
                        <span class="pub_sort">\
                            <a sort="title" rel="nofollow" title="up" style="cursor:pointer;">∧</a>\
                            <a sort="title-desc" rel="nofollow" title="down" style="cursor:pointer;">∨</a>\
                        </span>\
                    </th>\
                    <th class="last">\
                        <p>Year</p>\
                        <span class="pub_sort">\
                            <a sort="year" rel="nofollow" title="up" style="cursor:pointer;">∧</a>\
                            <a sort="year-desc" rel="nofollow" title="down" style="cursor:pointer;color:#000000">∨</a>\
                        </span>\
                    </th>\
                </tr>\
            ');
        $('.tamboti-result-table-header').append($html);
        if (this.options.embedVRA){
            $vraHeader = $('<th>Image</th>');
            $($html.children()[this.options.vraPos]).after($vraHeader);
        }
    },
    
    setLoading: function(){
        $('#results').empty();
        var html = '\
                <tr>\
                    <td colspan="4" style="text-align:center;">\
                        <img src="' + TambotiColViewer.options.tambotiURL + '/resources/images/ajax-loader.gif" />\
                    </td>\
                </tr>';
        $('#results').append(html);
    },
    
    updateVars: function(start, limit, familyNameStartingWith, orderBy, desc, filterByYear){
        var variableDiv = $('#tamboti-collection');
        variableDiv.attr('start', start);
        variableDiv.attr('limit', limit);
        variableDiv.attr('family-name-starting-with', familyNameStartingWith);
        variableDiv.attr('order-by', orderBy);
        variableDiv.attr('desc', desc);
        variableDiv.attr('filter-by-year', filterByYear);
    },
    
    getVars: function() {
        return $('#tamboti-collection').attributes;
    },
    
    fillYearDropdown: function(years) {
        var activeYear = $('#tamboti-collection').attr('filter-by-year');
    
        $('.tamboti-years').empty();
        $('.tamboti-years').append('<option value="">All</option>\n');
        for (var i in years){
            $('.tamboti-years').append('<option id="' + years[i] + '" value="'+ years[i] +'">' + years[i] + '</option>\n');
        }
        if(activeYear)
            $('.tamboti-years > option#' + activeYear).attr('selected', 'selected');
    },
    
    fillGenreDropdown: function(genres) {
        var activeGenre = $('#tamboti-collection').attr('filter-by-genre');
    
        $('.tamboti-genres').empty();
        $('.tamboti-genres').append('<option value="">All</option>\n');
        for (var i in genres){
            $('.tamboti-genres').append('<option id="genre_' + genres[i] + '" value="' + genres[i] + '");">' + genres[i] + '</option>\n');
        }
        if(activeGenre)
            $('.tamboti-genres > option#genre_' + activeGenre).attr('selected', 'selected');
    },
    
    setFilterYear: function(year){
        $('#tamboti-collection').attr('filter-by-year', year?year:'');
        $('#tamboti-collection').attr('start', 1);
        TambotiColViewer.updateResults();
    },
    
    setFilterGenre: function(genre){
        $('#tamboti-collection').attr('filter-by-genre', genre?genre:'');
        $('#tamboti-collection').attr('start', 1);
        TambotiColViewer.updateResults();
    },
    
    setLimit: function(limit){
        $('#tamboti-collection').attr('limit', limit);
        TambotiColViewer.updateResults();
    },
    
    updateResults: function(){
        var start = $('#tamboti-collection').attr('start');
        var limit = $('.tamboti-limit').val();
        var familyNameStartingWith = $('#tamboti-collection').attr('family-name-starting-with');
        var filterByYear = $('.tamboti-years').val();
        var filterByGenre = $('.tamboti-genres').val();
        var filterByFamilyName = $('.tamboti-familyName option:selected').val();
        var filterByGivenName = $('.tamboti-givenName option:selected').val();

        var orderBy = $('#tamboti-collection').attr('order-by');
        var desc = $('#tamboti-collection').attr('desc');
        // Remove all entries and display loading spinner
        TambotiColViewer.setLoading();
        
        $.ajax({
            crossDomain: true,
            url: TambotiColViewer.options.tambotiURL + TambotiColViewer.options.tambotiService,
            data: {
                collection: TambotiColViewer.options.collection,
                start: start,
                limit: limit,
                familyNameStartingWith: familyNameStartingWith,
                orderBy: orderBy,
                desc: desc,
                filterByYear: filterByYear,
                filterByGenre: filterByGenre,
                filterByFamilyName: filterByFamilyName,
                filterByGivenName: filterByGivenName
            },
            type: "POST",
            dataType : "json",
            success: function( json ) {
                var counterStart = parseInt(json.start, 10);
                var counterTo = parseInt(json.limit, 10) - 1;
                var pages = Math.ceil(json.count / limit);
    
                $('#results').empty();
                $(".counter-from").html(Math.min(json.start, json.count));
                $(".counter-to").html(Math.min(json.count, (counterStart + counterTo)));
                $(".counter-total").html(json.count);
    
                for (var i in json.entries){
                    TambotiColViewer.addRow(json.entries[i], (i % 2 === 0));
                }
                TambotiColViewer.updateStartingChars(familyNameStartingWith);
    
                TambotiColViewer.updatePagination(json.count);
                TambotiColViewer.fillYearDropdown(json.distinctYears);
                TambotiColViewer.fillGenreDropdown(json.distinctGenres);
            },
            error: function( xhr, status, errorThrown ) {
                $('#results').empty();
                var html = '\
                    <tr>\
                        <td colspan="3" style="text-align:center;">\
                            Error loading data.\
                        </td>\
                    </tr>';
                $('#results').append(html);
                if(typeof console !== "undefined"){
                    console.log( "Error: " + errorThrown );
                    console.log( "Status: " + status );
                    // console.dir( xhr );
                }
            }
         
        });
    },
    
    addRow: function(entryData, evenOdd){
        $tr = $('<tr class="' + (evenOdd?"even":"odd") + '"></tr>');
    
        $title_href = $('<a style="cursor:pointer;">' + entryData.title + '</a>');
        $title_href.bind("click", function(){
            TambotiColViewer.showResource(entryData);
        });
        
        $year_href = $('<a style="cursor:pointer;" rel="nofollow">' + entryData.year + '</a>');
        $year_href.bind("click", function(){
            TambotiColViewer.setFilterYear(entryData.year);
        });
    
        $td_author = $('<td class="first"></td>');
        var authors = [];
        // Construct authors array
        for (var idx in entryData.person){
            if(entryData.person[idx].fullName) {
                var author = entryData.person[idx].fullName;
                if (entryData.person[idx].role !== "aut")
                    author += ' (' + entryData.person[idx].role + ')';
                authors.push(author);
            }
        }
        $authors = authors.join("<br/>");
        $td_author = $('<td class="first"></td>');
        $td_title = $('<td></td>');
        $td_year = $('<td></td>');
    
        $("#results").append($tr);
        $tr.append($td_author);
        $td_author.append($authors);
        $tr.append($td_title);
        $td_title.append($title_href);
    
        $tr.append($td_year);
        $td_year.append($year_href);

        if (this.options.embedVRA){
            $vraHeader = $('<td></td>');
            for (var i in entryData.relatedItem){
                if($vraHeader.val() === '' && entryData.relatedItem[i].type == 'otherVersion' && entryData.relatedItem[i].tambotiImageUuid){
                    $vraHeader.append('<img src="' + TambotiColViewer.options.tambotiImageService + '?uuid=' + entryData.relatedItem[i].tambotiImageUuid + '&width=150"/>');
                }
            }
            $($tr.children()[this.options.vraPos]).after($vraHeader);
        }

    },
    
    setActiveStartingChar: function(active){
        var limit = $('#tamboti-collection').attr('limit');
        TambotiColViewer.updateVars(1, limit, active?active:"", "", "", "");
        TambotiColViewer.updateDistinctFamilyNames();
        TambotiColViewer.updateDistinctGivenNames();
        TambotiColViewer.updateResults();
    },
    
    updateStartingChars: function(active){
        var start = 65;
        var end = 90;
        $('.starting-chars').empty();
        if(!active) 
            $('.starting-chars').append('<strong>All</strong>');
        else
            $('.starting-chars').append('<a rel="nofollow" style="cursor:pointer;" onclick="TambotiColViewer.setActiveStartingChar(false);">All</a>');
    
        for (var c = start; c <= end; c++)    {
            var char = String.fromCharCode(c);
            if(char == active){
                $('.starting-chars').append(' | <strong>' + char + '</strong>');
            }else{
                $href = 
                $('.starting-chars').append(' | <a rel="nofollow" style="cursor:pointer;" onclick="TambotiColViewer.setActiveStartingChar(\'' + char + '\');">' + char + '</a>');
            }
        }
    },
    
    setPage: function(page){
        $('#tamboti-collection').attr('start', page);
    },
    
    updatePagination: function(count){
        var start = $('#tamboti-collection').attr('start');
        var limit = $('.tamboti-limit').val();

        $('.paginate').empty();
        
        var activePage = Math.ceil(start / limit);
        var pages = Math.ceil(count / limit);
    
        if (activePage != 1){
            $('.paginate').append("<li style='cursor:pointer;' onclick='TambotiColViewer.setPage(" + (((activePage - 2) * limit) + 1) + ");TambotiColViewer.updateResults()';'>Prev</li>");
        }
        for (var c = 1; c <= pages; c++ ) {
            if(c == activePage)
                $('.paginate').append("<li><strong>" + c + "</strong></li>");
            else
                $('.paginate').append("<li style='cursor:pointer;' onclick='TambotiColViewer.setPage(" + (((c - 1) * limit) + 1) + ");TambotiColViewer.updateResults();'>" + c + "</li>");
        }
        if (activePage != pages){
            // $('#tamboti-collection').attr('start', ((activePage * limit) + 1));
            $('.paginate').append("<li style='cursor:pointer;' onclick='TambotiColViewer.setPage(" + ((activePage * limit) + 1) + ");TambotiColViewer.updateResults();'>Next</li>");
        }
    },
    
    showResource: function(entryData){
        $.ajax({
            crossDomain: true,
            url: TambotiColViewer.options.tambotiURL + TambotiColViewer.options.tambotiService,
            data: {
                action: 'singleEntry',
                output: 'html',
                collection: TambotiColViewer.options.collection,
                uuid: entryData.uuid
            },
            type: "POST",
            dataType : "html",
            success: function( html ) {
                $html = $(html);
                $html.find("span.title").css("font-style", "italic");
                var url = "<a target=\"_blank\" href=\"" + TambotiColViewer.options.tambotiURL + "/modules/search/index.html?search-field=ID&value=" + entryData.uuid + "\">open in Tamboti</a>";
                var backlink = '<div class="back" style="cursor:pointer; background: url(\'http://www.asia-europe.uni-heidelberg.de/fileadmin/templates/main/images/fp2_images/arrow_fp2.gif\') no-repeat scroll 0 4px transparent;padding-left: 20px !important;"><a onclick="TambotiColViewer.hideResource();">Back</a></div>';
                
                $("#tamboti-resource").empty();
                
                $dataDisplay = $('<span style="display:table-cell;vertical-align:middle;"></span>');
                $dataDisplay.append($html);
                $resourceDiv = $('<div class="tamboti-display-resource" style="display:table;"></div>');

                if (entryData.locationURL.url)
                    $dataDisplay.append('<div><a href="' + entryData.locationURL.url + '" target="_blank">' + entryData.locationURL.url + '</a></div>');
                
                if (TambotiColViewer.options.embedVRA){
                    $imageDisplay = $('<span style="display:table-cell;vertical-align:middle;"></span>');
                    for (var i in entryData.relatedItem){
                        if($imageDisplay.val() === '' && entryData.relatedItem[i].type == 'otherVersion' && entryData.relatedItem[i].tambotiImageUuid){
                            $imageDisplay.append('<img src="' + TambotiColViewer.options.tambotiImageService + '?uuid=' + entryData.relatedItem[i].tambotiImageUuid + '&width=300"/>');
                        }
                    }
                    $resourceDiv.append($imageDisplay);
                }
                
                $resourceDiv.append($dataDisplay);
                $("#tamboti-resource").append($resourceDiv);
                $("#tamboti-resource").append("<div>" + url + "</div><br/>");
                $("#tamboti-resource").append("<div>" + backlink + "</div>");

                $("#tamboti-collection").hide();
                $("#tamboti-resource").show();
                
            },
            error: function( xhr, status, errorThrown ) {
                $('#results').empty();
                var html = '\
                    <tr>\
                        <td colspan="3" style="text-align:center;">\
                            Error loading data.\
                        </td>\
                    </tr>';
                $('#results').append(html);
                if(typeof console !== "undefined"){
                    console.log( "Error: " + errorThrown );
                    console.log( "Status: " + status );
                    // console.dir( xhr );
                }
            }
         
        });
    },
    
    hideResource: function(){
        $("#tamboti-resource").hide();
        $("#tamboti-collection").show();
    }
    
    // getMODS: function(uuid){
    //     // get MODS using tamboti's source.xql
    //     $.ajax({
    //         crossDomain: true,
    //         url: "http://kjc-ws2.kjc.uni-heidelberg.de:8650/exist/apps/tamboti/modules/search/source.xql",
    //         data:{ 
    //             id: uuid
    //         },
    //         type: "POST",
    //         dataType : "xml",
    //         success: function(  ) {
    //         },
    //         error: function( xhr, status, errorThrown ) {
    //             $('#results').empty();
    //             var html = '\
    //                 <tr>\
    //                     <td colspan="3" style="text-align:center;">\
    //                         Error loading data.\
    //                     </td>\
    //                 </tr>';
    //             $('#results').append(html);
    
                // if(typeof console !== "undefined"){
                //     console.log( "Error: " + errorThrown );
                //     console.log( "Status: " + status );
                //     console.dir( xhr );
                // }
    //         }
         
    //     });
    
    // }
};