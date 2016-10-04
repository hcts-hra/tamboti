<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:tmx="http://www.lisa.org/tmx14">
    <head>
        <meta http-equiv="Content-Type" content="text/xml; charset=UTF-8"/>
        <title>Trigger control rendered as link</title>
        <script src="../../resources/scripts/jquery-1.11.2/jquery-1.11.2.min.js">/**/</script>
        <script type="text/javascript" src="../../resources/scripts/jquery-ui-1.11.4/jquery-ui.min.js">/**/</script>
        <link rel="stylesheet" type="text/css" href="../../resources/scripts/jquery-ui-1.11.4/jquery-ui.min.css"/>
        <link rel="stylesheet" type="text/css" href="../../themes/tamboti/css/theme.css"/>
        <script type="text/javascript">
            $(document).ready(function() {
                $("#filters-selector").on("click", "a", function() {
                    var $this = $(this);
                    var filterId = this.id;
                    var filterUrl = "../../modules/filters/" + filterId.replace("i-i18n", "") + ".xql";
                    
                    $("img", $this).show();
                    
                    $.ajax({
                        url: filterUrl,
                        dataType: "text",
                        type: "GET",
                        success: function (data) {
                        	alert(JSON.parse(data));
                        }
                    });        
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
                    <xf:send submission="s-get-filters"/>
                </xf:action>
                <xf:action ev:event="filters:loaded" ev:observer="body">
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
            <div id="filters-selector">
                <xf:group appearance="minimal" model="m-filters">
                    <xf:select1 ref="instance('i-variables')/selected-filter" appearance="full" incremental="true">
                        <xf:itemset nodeset="instance('i-configuration')/filter-ids/filter">
                            <xf:label ref="let $id := @id return instance('i-i18n')//tmx:tu[@tuid = concat($id, '-filter')]/tmx:tuv[@xml:lang = instance('i-variables')/ui-language]/tmx:seg"/>
                            <xf:value ref="@id"/>
                        </xf:itemset>
                        <xf:dispatch ev:event="xforms-value-changed" name="filters:filter-type-selected" targetid="body"/>
                    </xf:select1>
                    <xf:output ref="instance('i-configuration')/progress-indicator" mediatype="image/gif"/>
                </xf:group>
            </div>
            <div id="filters-renderer"/>
        </div>
    </body>
</html>