<html xmlns="http://www.w3.org/1999/xhtml" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:tmx="http://www.lisa.org/tmx14">
    <head>
        <meta http-equiv="Content-Type" content="text/xml; charset=UTF-8"/>
        <title>Trigger control rendered as link</title>
        <script src="../../resources/scripts/jquery-1.11.2/jquery-1.11.2.min.js">/**/</script>
        <script type="text/javascript" src="../../resources/scripts/jquery-ui-1.11.4/jquery-ui.min.js">/**/</script>
        <script src="https://cdn.rawgit.com/gwendall/way.js/master/way.min.js"/>
        <link rel="stylesheet" type="text/css" href="../../resources/scripts/jquery-ui-1.11.4/jquery-ui.min.css"/>
        <link rel="stylesheet" type="text/css" href="../../themes/tamboti/css/theme.css"/>
        <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css"/>
        <script type="text/javascript" src="filters-module.js">/**/</script>
        <script type="text/javascript" src="../../modules/filters/filters.js">/**/</script>
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
                        <filters>
                            <filter id="title-words" exclusions=".png$|.jpg$|^[0-9\\_\\.,]+$"/>
                            <filter id="names" exclusions=""/>
                            <filter id="dates" exclusions=""/>
                            <filter id="subjects" exclusions=""/>
                            <filter id="languages" exclusions=""/>
                            <filter id="genres" exclusions=""/>
                            <filter id="test" exclusions=""/>
                        </filters>
                        <progress-indicator relevant="false">../../themes/default/images/ajax-loader-small.gif</progress-indicator>
                    </configuration>
                </xf:instance>
                <xf:instance id="i-variables">
                    <variables xmlns="">
                        <ui-language>en</ui-language>
                        <selected-filter/>
                        <apply-exclusions>true</apply-exclusions>
                    </variables>
                </xf:instance>
                <xf:instance id="i-i18n" src="../../modules/filters/tmx.xml"/>
                <xf:instance id="i-filters">
                    <filters xmlns=""/>
                </xf:instance>
                <xf:bind ref="instance('i-configuration')/progress-indicator" relevant="@relevant = 'true'"/>
                <xf:bind id="exclusions-group" relevant="instance('i-configuration')//filter[@id = instance('i-variables')/selected-filter]/@exclusions != ''"/>
                <xf:bind ref="instance('i-variables')/apply-exclusions" type="xf:boolean"/>
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
                    <script type="text/javascript">
						fluxProcessor.dispatchEventType("body", "filters:load-filters", {});
                    </script>
                </xf:action>
                <xf:action ev:event="filters:load-filters" ev:observer="body">
                    <script type="text/javascript">
                        tamboti.filters.actions['removeFilters']();
                        way.set("dataInstances.variables.firstFilterDisplayedIndex", "0");
                        way.set("dataInstances.variables.lastFilterDisplayedIndex", "0");
                        way.set("dataInstances.variables.totalFiltersNumber", "0");
                        
                        var selectedFilter = $("#selected-filter-select input:checked").val();
                        
                        $.ajax({
                            url: "../../modules/filters/" + selectedFilter + ".xql",
                            dataType: "json",
                            type: "GET",
                            success: function (data) {
                                var data = (data || {"filter": [{"filter": "", "#text": "", "frequency": ""}]}).filter;
                                var exclusions = $("#exclusions-output").text();
                                
                                if (exclusions != '') {
                                    tamboti.filters.dataInstances['original-filters'] = data;
                                    data = tamboti.filters.actions['applyExcludes'](data, exclusions);
                                }
                                
                            	tamboti.filters.dataInstances['filters'] = data;
                            	way.set("dataInstances.variables.totalFiltersNumber", data.length);
                            	
                            	fluxProcessor.dispatchEventType("body", "filters:loaded", {});
                            }
                        });				
                    </script>
                </xf:action>
                <xf:action ev:event="filters:loaded" ev:observer="body">
                    <script type="text/javascript">
                        tamboti.filters.actions['renderFilters'](tamboti.filters.dataInstances['filters']);
                        
                            // var filters = way.get("dataInstances.filters");
                            // var filtersNumber = filters.length;
                            
                            // var div = document.createElement('div');
                            // div.setAttribute("class", "filter-view");
                            
                            // var wrapperHeight = $wrapper.height();
                            // var lastFilterOffsetBottom = 0;
                            // var threshold = 0;
                            // var filterIndex = 0;
                            // var $filtersContainer = $("#filters-renderer");
                            // var lineHeight = $filtersContainer.css('line-height').replace("px", "");
                            
                            // while (lastFilterOffsetBottom &lt; wrapperHeight + 5 * lineHeight &amp;&amp; filterIndex &lt; filtersNumber) {
                            //     var filter = filters[filterIndex];
                            //     div.textContent = filter['#text'] + ' [' + filter['frequency'] + ']';
                            //     $this = $(div.cloneNode(true)).appendTo($filtersContainer);
                                
                            //     lastFilterOffsetBottom = $this.offset().top + $this.height() + threshold;
                            //     filterIndex++;
                            // }                            
                            
                            // way.set("dataInstances.variables.firstFilterDisplayedIndex", 1);
                            // way.set("dataInstances.variables.lastFilterDisplayedIndex", filterIndex);
                    </script>
                    <xf:setvalue ref="instance('i-configuration')/progress-indicator/@relevant">false</xf:setvalue>
                </xf:action>
                <xf:action ev:event="filters:apply-exclusions" ev:observer="body">
                    <xf:action if="instance('i-variables')/apply-exclusions = 'true'">
                        <script type="text/javascript">
                            tamboti.filters.actions['removeFilters']();
                            way.set("dataInstances.variables.firstFilterDisplayedIndex", "0");
                            way.set("dataInstances.variables.lastFilterDisplayedIndex", "0");
                            way.set("dataInstances.variables.totalFiltersNumber", "0");
                            
                            var data = tamboti.filters.dataInstances['original-filters'];
                            var exclusions = $("#exclusions-output").text();
                            
                            data = tamboti.filters.actions['applyExcludes'](data, exclusions);
                            
                        	tamboti.filters.dataInstances['filters'] = data;
                        	way.set("dataInstances.variables.totalFiltersNumber", data.length);
                        	
                        	fluxProcessor.dispatchEventType("body", "filters:loaded", {});
                        </script>
                    </xf:action>
                    <xf:action if="instance('i-variables')/apply-exclusions = 'false'">
                        <script type="text/javascript">
                            tamboti.filters.actions['removeFilters']();
                            way.set("dataInstances.variables.firstFilterDisplayedIndex", "0");
                            way.set("dataInstances.variables.lastFilterDisplayedIndex", "0");
                            way.set("dataInstances.variables.totalFiltersNumber", "0");
                            
                            var data = tamboti.filters.dataInstances['original-filters'];
                            
                        	tamboti.filters.dataInstances['filters'] = data;
                        	way.set("dataInstances.variables.totalFiltersNumber", data.length);
                        	
                        	fluxProcessor.dispatchEventType("body", "filters:loaded", {});
                        </script>
                    </xf:action>
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
                    <xf:itemset nodeset="instance('i-configuration')/filters/filter">
                        <xf:label ref="let $id := @id return instance('i-i18n')//tmx:tu[@tuid = concat($id, '-filter')]/tmx:tuv[@xml:lang = instance('i-variables')/ui-language]/tmx:seg"/>
                        <xf:value ref="@id"/>
                    </xf:itemset>
                    <xf:dispatch ev:event="xforms-value-changed" name="filters:filter-type-selected" targetid="body"/>
                </xf:select1>
                <xf:output ref="instance('i-configuration')/progress-indicator" mediatype="image/gif"/>
            </xf:group>
            <div id="filters-navigator" way-scope="dataInstances.variables">
                <div class="fa fa-sort-alpha-desc" style="padding: 5px;" onclick="tamboti.filters.actions['sortFilters'](this);"/>
                <div class="fa fa-sort-amount-asc" style="padding: 5px;" onclick="tamboti.filters.actions['sortFilters'](this);"/>
                viewing 
                <output way-data="firstFilterDisplayedIndex"/>
                 to 
                <output way-data="lastFilterDisplayedIndex"/>
                 out of 
                <output way-data="totalFiltersNumber"/>
                 filters
            </div>
            <xf:group bind="exclusions-group" model="m-filters">
                <xf:label ref="instance('i-i18n')//tmx:tu[@tuid = 'exclusions']/tmx:tuv[@xml:lang = instance('i-variables')/ui-language]/tmx:seg"/>
                <xf:output id="exclusions-output" ref="instance('i-configuration')//filter[@id = instance('i-variables')/selected-filter]/@exclusions"/>
                <xf:input ref="instance('i-variables')/apply-exclusions" incremental="true">
                    <xf:dispatch ev:event="xforms-value-changed" name="filters:apply-exclusions" targetid="body"/>
                </xf:input>
            </xf:group>
            <div id="filters-renderer-container">
                <div id="filters-renderer"/>
            </div>
        </div>
    </body>
</html>