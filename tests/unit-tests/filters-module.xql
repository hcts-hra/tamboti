<html xmlns="http://www.w3.org/1999/xhtml" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:tmx="http://www.lisa.org/tmx14">
    <head>
        <meta http-equiv="Content-Type" content="text/xml; charset=UTF-8"/>
        <title>Filters Module Unit Test</title>
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
                            <filter id="title-words">
                                <exclusions>
                                    <exclusion title="png">.png$</exclusion>
                                    <exclusion title="jpg">.jpg$</exclusion>
                                    <exclusion title="digits, etc.">^[0-9\\_\\.,]+$</exclusion>
                                    <exclusion title="non-latin scripts">^[\w\u00C0-\u024f]+$</exclusion>
                                </exclusions>
                            </filter>
                            <filter id="names" exclusions=""/>
                            <filter id="dates" exclusions=""/>
                            <filter id="subjects" exclusions=""/>
                            <filter id="languages" exclusions=""/>
                            <filter id="genres" exclusions=""/>
                            <filter id="test" exclusions=""/>
                        </filters>
                    </configuration>
                </xf:instance>
                <xf:instance id="i-variables">
                    <variables xmlns="">
                        <progress-indicator relevant="false">../../themes/default/images/ajax-loader-small.gif</progress-indicator>
                        <ui-language>en</ui-language>
                        <selected-filter/>
                        <selected-exclusions/>
                        <exclusions-initialized>false</exclusions-initialized>
                    </variables>
                </xf:instance>
                <xf:instance id="i-i18n" src="../../modules/filters/tmx.xml"/>
                <xf:instance id="i-filters">
                    <filters xmlns=""/>
                </xf:instance>
                <xf:bind ref="instance('i-variables')/progress-indicator" relevant="@relevant = 'true'"/>
                <xf:bind id="exclusions-group" relevant="instance('i-configuration')//filter[@id = instance('i-variables')/selected-filter]/exclusions/exclusion != ''"/>
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
                    <xf:setvalue ref="instance('i-variables')/exclusions-initialized">false</xf:setvalue>
                    <xf:setvalue ref="instance('i-variables')/selected-exclusions" value="string-join(instance('i-configuration')//filter[@id = instance('i-variables')/selected-filter]/exclusions/exclusion, ' ')"/>
                    <script type="text/javascript">
						fluxProcessor.dispatchEventType("body", "filters:load-filters", {});
                    </script>
                </xf:action>
                <xf:action ev:event="filters:load-filters" ev:observer="body">
                    <script type="text/javascript">
                        tamboti.filters.actions['removeFilters']();
                        way.set("dataInstances.variables.firstDisplayedFilterIndex", "0");
                        way.set("dataInstances.variables.lastDisplayedFilterIndex", "0");
                        way.set("dataInstances.variables.totalFiltersNumber", "0");
                        
                        var selectedFilter = $("#selected-filter-select input:checked").val();
                        
                        $.ajax({
                            url: "../../modules/filters/" + selectedFilter + ".xql",
                            dataType: "json",
                            type: "GET",
                            success: function (data) {
                                var data = (data || {"filter": [{"filter": "", "label": "", "frequency": ""}]}).filter;
                                
                                var exclusions = tamboti.filters.actions['getExclusions']();
                                if (exclusions != '') {
                                    tamboti.filters.dataInstances['original-filters'] = data;
                                    data = tamboti.filters.actions['applyExclusions'](data, exclusions);
                                }
                                
                            	tamboti.filters.dataInstances['filters'] = data;
                            	way.set("dataInstances.variables.totalFiltersNumber", data.length);
                            	
                            	fluxProcessor.dispatchEventType("body", "filters:loaded", {});
                            }
                        });				
                    </script>
                </xf:action>
                <xf:action if="instance('i-variables')/exclusions-initialized = 'true'" ev:event="filters:apply-exclusions" ev:observer="body">
                    <script type="text/javascript">
                        tamboti.filters.actions['removeFilters']();
                        
                        way.set("dataInstances.variables.firstDisplayedFilterIndex", "0");
                        way.set("dataInstances.variables.lastDisplayedFilterIndex", "0");
                        way.set("dataInstances.variables.totalFiltersNumber", "0");
                        
                        var data = tamboti.filters.dataInstances['original-filters'];
                        var exclusions = tamboti.filters.actions['getExclusions']();

                        data = tamboti.filters.actions['applyExclusions'](data, exclusions);
                        
                    	tamboti.filters.dataInstances['filters'] = data;
                    	way.set("dataInstances.variables.totalFiltersNumber", data.length);
                    	
                    	fluxProcessor.dispatchEventType("body", "filters:loaded", {});
                    </script>
                </xf:action>
                <xf:action ev:event="filters:loaded" ev:observer="body">
                    <script type="text/javascript">
                        tamboti.filters.actions['renderFilters'](tamboti.filters.dataInstances['filters']);
                        
                        fluxProcessor.dispatchEventType("body", "filters:end-processing", {});
                    </script>
                    <xf:setvalue ref="instance('i-variables')/exclusions-initialized">true</xf:setvalue>
                </xf:action>                
                <xf:action ev:event="filters:start-processing" ev:observer="body">
                    <xf:setvalue ref="instance('i-variables')/progress-indicator/@relevant">true</xf:setvalue>
                </xf:action>
                <xf:action ev:event="filters:end-processing" ev:observer="body">
                    <xf:setvalue ref="instance('i-variables')/progress-indicator/@relevant">false</xf:setvalue>                    
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
                    <xf:dispatch ev:event="xforms-value-changed" name="filters:start-processing" targetid="body"/>
                    <xf:dispatch ev:event="xforms-value-changed" name="filters:filter-type-selected" targetid="body"/>
                </xf:select1>
                <xf:output ref="instance('i-variables')/progress-indicator" mediatype="image/gif"/>
            </xf:group>
            <div id="filters-navigator" way-scope="dataInstances.variables">
                <div class="fa fa-sort-alpha-desc" style="padding: 5px;" onclick="tamboti.filters.actions['sortFilters'](this);"/>
                <div class="fa fa-sort-amount-asc" style="padding: 5px;" onclick="tamboti.filters.actions['sortFilters'](this);"/>
                viewing 
                <output way-data="firstDisplayedFilterIndex"/>
                 to 
                <output way-data="lastDisplayedFilterIndex"/>
                 out of 
                <output way-data="totalFiltersNumber"/>
                 filters
            </div>
            <xf:group bind="exclusions-group" model="m-filters">
                <xf:select id="exclusions-select" ref="instance('i-variables')/selected-exclusions" appearance="full" incremental="true">
                    <xf:label ref="instance('i-i18n')//tmx:tu[@tuid = 'exclusions']/tmx:tuv[@xml:lang = instance('i-variables')/ui-language]/tmx:seg"/>
                    <xf:itemset ref="instance('i-configuration')//filter[@id = instance('i-variables')/selected-filter]/exclusions/exclusion">
                        <xf:label ref="@title"/>
                        <xf:value ref="."/>
                    </xf:itemset>
                    <xf:dispatch ev:event="xforms-value-changed" name="filters:apply-exclusions" targetid="body"/>
                </xf:select>
            </xf:group>
            <div id="filters-renderer"/>
        </div>
    </body>
</html>