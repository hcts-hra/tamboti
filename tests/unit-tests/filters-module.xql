<html xmlns="http://www.w3.org/1999/xhtml" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:tmx="http://www.lisa.org/tmx14">
    <head>
        <meta http-equiv="Content-Type" content="text/xml; charset=UTF-8"/>
        <title>Trigger control rendered as link</title>
        <script src="../../resources/scripts/jquery-1.11.2/jquery-1.11.2.min.js">/**/</script>
        <script type="text/javascript" src="../../resources/scripts/jquery-ui-1.11.4/jquery-ui.min.js">/**/</script>
        <link rel="stylesheet" type="text/css" href="../../resources/scripts/jquery-ui-1.11.4/jquery-ui.min.css"/>
        <link rel="stylesheet" type="text/css" href="../../themes/tamboti/css/theme.css"/>
        <link rel="stylesheet" href="../../resources/css/font-awesome/css/font-awesome.min.css"/>
        <script type="text/javascript">
            $(document).ready(function() {
                tamboti = {};
                tamboti.filters = {};
                
                tamboti.filters.filterName = "";
                tamboti.filters.dataInstances = {};
                
var wrapper = document.getElementById("filters-renderer-container");
var $wrapper = $(wrapper);

var filterDiv = document.createElement('div');
filterDiv.setAttribute("class", "filter-view");

wrapper.addEventListener("scroll", function (event) {
    checkForNewDiv();
});

var checkForNewDiv = function () {
    var lastDiv = document.querySelector("#filters-renderer > div:last-child");
    var lastDivOffset = lastDiv.offsetTop + lastDiv.clientHeight;
    var pageOffset = wrapper.scrollTop + wrapper.clientHeight;

    if (pageOffset > lastDivOffset - 10) {
        newDiv.innerHTML = performance.now();
        
        for (i = 0; i &lt; 6; i++) {
            document.getElementById("scroll-content").appendChild(filterDiv.cloneNode(true));
        }
        checkForNewDiv();
        
        //$("#scroll-content > div", $wrapper).slice(0, 5).detach();
    }
};

checkForNewDiv();                
                

                $("#filters-renderer-container").on("click", "div.filter-view", function() {
                    var $this = $(this);
                    
                    $this.addClass("selected-filter-view");
                    
                    var filterId = this.id;
                    var filterUrl = "../../modules/filters/" + filterId.replace("i-i18n", "") + ".xql";
                });
            });
                
                
            </script>
    </head>
    <body class="soria" style="margin:30px" id="body">
        <div style="display:none">
            <xf:model id="m-main">
                <xf:instance id="i-configuration">
                    <configuration xmlns="">
                        <languages>
                            <language>en</language>
                            <language>de</language>
                            <language>fr</language>
                        </languages>
                        <current-username/>
                    </configuration>
                </xf:instance>
                <xf:instance id="i-variables">
                    <variables xmlns="">
                        <ui-language>en</ui-language>
                    </variables>
                </xf:instance>
            </xf:model>
            <xf:model id="m-filters">
                <xf:instance id="i-configuration">
                    <configuration xmlns="">
                        <filter-ids>
                            <filter id="title-words"/>
                            <filter id="names"/>
                            <filter id="dates"/>
                            <filter id="subjects"/>
                            <filter id="languages"/>
                            <filter id="genres"/>
                        </filter-ids>
                        <progress-indicator relevant="false">../../themes/default/images/ajax-loader-small.gif</progress-indicator>
                        <filters-iterator>1</filters-iterator>
                    </configuration>
                </xf:instance>
                <xf:instance id="i-variables">
                    <variables xmlns="">
                        <ui-language>en</ui-language>
                        <selected-filter/>
                    </variables>
                </xf:instance>
                <xf:instance id="i-i18n" src="tmx.xml"/>
                <xf:instance id="i-filters">
                    <filters xmlns=""/>
                </xf:instance>
                <xf:bind ref="instance('i-configuration')/progress-indicator" relevant="@relevant = 'true'"/>
                <xf:submission id="s-get-filters" method="get" resource="../../modules/filters/{instance('i-variables')/selected-filter}.xql" replace="instance" instance="i-filters">
                    <xf:action ev:event="xforms-submit-done">
                        <xf:dispatch name="filters:loaded" targetid="body"/>
                    </xf:action>
                    <xf:message ev:event="xforms-submit-error" level="modal">A submission error (<xf:output value="event('response-reason-phrase')"/>) occurred. Details: 'response-status-code' = '<xf:output value="event('response-status-code')"/>', 'resource-uri' = '<xf:output value="event('resource-uri')"/>'.</xf:message>
                </xf:submission>
                <xf:action ev:event="tamboti:ui-language-changed" ev:observer="body">
                    <xf:setvalue ref="instance('i-variables')/ui-language" value="event('ui-language')"/>
                </xf:action>
                <xf:action ev:event="filters:filter-type-selected" ev:observer="body">
                    <xf:setvalue ref="instance('i-configuration')/progress-indicator/@relevant">true</xf:setvalue>
                    <script>
						fluxProcessor.dispatchEventType("body", "filters:load-filters", {});
                    </script>
                </xf:action>
                <xf:action ev:event="filters:load-filters" ev:observer="body">
                    <script>
                        $.ajax({
                            url: "../../modules/filters/" + $("#selected-filter-select input:checked").val() + ".xql",
                            dataType: "json",
                            type: "GET",
                            success: function (data) {
                            	tamboti.filters.dataInstances['filters'] = data;
                            	fluxProcessor.dispatchEventType("body", "filters:loaded", {});
                            }
                        });				
                    </script>
                </xf:action>
                <xf:action ev:event="filters:loaded" ev:observer="body">
                    <script>
                        
                            var t0 = performance.now();

                            var filters = tamboti.filters.dataInstances['filters']['filter'];
                            var filtersLength = filters.length;
                            
                            var fragment = document.createDocumentFragment();
                            
                            var div = document.createElement('div');
                            div.setAttribute("class", "filter-view");
                            
                            for (var i = 1; i &lt;= filtersLength; i++) {
                                div.textContent = filters[i-1]['#text'] + ' [' + filters[i-1]['frequency'] + ']';
                                fragment.appendChild(div.cloneNode(true));
                            }
                            
                            
                            $("#filters-renderer")[0].appendChild(fragment);
                            
                            var t1 = performance.now();
                            console.log("Call to html() took " + (t1 - t0) / 1000 + " milliseconds.")  
                            
var t0 = performance.now();

var i;

for(i=0;i&lt;86400;i++)
{
    $('#filters-renderer').append('&lt;div class="filter-view"&gt;'+i+' sec&lt;/div&gt;');
}

var t1 = performance.now();
console.log("Call to html() took " + (t1 - t0) / 1000 + " seconds.")




var t0 = performance.now();

$('#filters-renderer').empty();

var i;
var units = '';

for(i=0;i&lt;86400;i++){
    units +='<div>' + t0 + 'sec</div>';
}

$('#filters-renderer').append(units);

var t1 = performance.now();
console.log("Call to html() took " + (t1 - t0) / 1000 + " seconds.")
                            
                        
                    </script>
                    <xf:setvalue ref="instance('i-configuration')/progress-indicator/@relevant">false</xf:setvalue>
                </xf:action>
            </xf:model>
        </div>
        <div style="float: right;">
            <xf:group appearance="full" model="m-main">
                <xf:select1 ref="instance('i-variables')/ui-language" appearance="minimal" incremental="true">
                    <xf:itemset ref="instance('i-configuration')/languages/language">
                        <xf:label ref="."/>
                        <xf:value ref="."/>
                    </xf:itemset>
                    <xf:dispatch ev:event="xforms-value-changed" name="tamboti:ui-language-changed" targetid="body">
                        <xf:contextinfo name="ui-language" value="instance('i-variables')/ui-language"/>
                    </xf:dispatch>
                </xf:select1>
            </xf:group>
        </div>
        <div id="filters">
            <xf:group appearance="minimal" model="m-filters">
                <xf:select1 id="selected-filter-select" ref="instance('i-variables')/selected-filter" appearance="full" incremental="true">
                    <xf:itemset nodeset="instance('i-configuration')/filter-ids/filter">
                        <xf:label ref="let $id := @id return instance('i-i18n')//tmx:tu[@tuid = concat($id, '-filter')]/tmx:tuv[@xml:lang = instance('i-variables')/ui-language]/tmx:seg"/>
                        <xf:value ref="@id"/>
                    </xf:itemset>
                    <xf:dispatch ev:event="xforms-value-changed" name="filters:filter-type-selected" targetid="body"/>
                </xf:select1>
                <xf:output ref="instance('i-configuration')/progress-indicator" mediatype="image/gif"/>
            </xf:group>
            <div id="filters-renderer-container">
                <div class="fa fa-sort-alpha-desc" style="padding: 5px;" onclick="alert('a');"/>
                <div class="fa fa-sort-amount-asc" style="padding: 5px;" onclick="alert('b');"/>
                <div id="filters-renderer"/>
            </div>
        </div>
    </body>
</html>