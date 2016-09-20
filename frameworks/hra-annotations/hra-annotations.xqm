xquery version "3.1";

module namespace hra-anno-framework = "http://hra.uni-heidelberg.de/ns/hra-anno-framework";

import module namespace config = "http://exist-db.org/mods/config" at "/apps/tamboti/modules/config.xqm";

import module namespace mongodb="http://expath.org/ns/mongo" at "java:org.exist.mongodb.xquery.MongodbModule";
import module namespace functx="http://www.functx.com";
import module namespace security = "http://exist-db.org/mods/security" at "/apps/tamboti/modules/search/security.xqm";

declare namespace c="http://hra.uni-heidelberg.de/ns/tamboti/annotations/config";
declare namespace xhtml="http://www.w3.org/1999/xhtml";

declare variable $hra-anno-framework:mongodbClientId := mongodb:connect($config:mongo-url);
declare variable $hra-anno-framework:tamboti-root := request:get-scheme() || "://" || request:get-server-name() || (if (request:get-server-port() = 80) then "" else ":" || request:get-server-port()) || "/exist/apps/tamboti/";
declare variable $hra-anno-framework:tamboti-api-root := $hra-anno-framework:tamboti-root || "api/";
declare variable $hra-anno-framework:MONGODB-ERROR := xs:QName("hra-anno-framework:mongodb-error");

declare variable $hra-anno-framework:json-serialize-parameters :=
    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
        <output:method value="json"/>
        <output:media-type value="text/javascript"/>
    </output:serialization-parameters>;


declare variable $hra-anno-framework:inaccessible-target-html := 
    <div class="resource">
        <div class="label">INACCESSIBLE</div>
        <div class="short">no access or unknown</div>
        <div class="detail">you either do not have access to the underlying resource or it's not available anymore</div>
        <div class="footer"/>
    </div>;

declare function hra-anno-framework:save-annotation($annotations-map as map(*)) {
    try {
        (: first look for existence of the annotation-id in mongodb  :)
        let $anno-id := $annotations-map?("id")
        let $found := mongodb:find($hra-anno-framework:mongodbClientId, $config:mongo-database, $config:mongo-anno-collection, "{'id': '" || $anno-id || "'}")
    
(:        let $log := util:log("INFO", "{'id': '" || $anno-id || "'}"):)
(:        let $log := util:log("INFO", $found):)
(:        let $log := util:log("INFO", count($found)):)
        let $anno-json := serialize($annotations-map, $hra-anno-framework:json-serialize-parameters)
        let $result := 
            if ($found) then
                mongodb:update($hra-anno-framework:mongodbClientId, $config:mongo-database, $config:mongo-anno-collection, "{'id': '" || $anno-id || "'}", $anno-json, true(), false())
            else
                mongodb:insert($hra-anno-framework:mongodbClientId, $config:mongo-database, $config:mongo-anno-collection, $anno-json)
    
        return
            xs:string($anno-id)
    } catch * {
        let $error := "Error: saving annotations failed with exception: " ||  $err:code || ": " || $err:description
        let $log := util:log("ERROR", $error)
        return
            error($hra-anno-framework:MONGODB-ERROR, "Saving annotation failed!")
    }
};

declare function hra-anno-framework:get-annotation($anno-id as xs:string){
    try {
        let $annotation := mongodb:find($hra-anno-framework:mongodbClientId, $config:mongo-database, $config:mongo-anno-collection, "{'id': '" || $anno-id || "'}", "{_id: 0}")
        return
            $annotation
    } catch * {
        error($hra-anno-framework:MONGODB-ERROR, "Getting Annotation failed!")
    }
};

declare function hra-anno-framework:get-annotationsFor($resource-uuid as xs:string, $as as xs:string*, $json as xs:boolean?) {
    try{
        let $or-query-substrings :=
            if (count($as) = 0) then
                "{body.id: {$regex: '" || $resource-uuid || "'}}"
            else
                (
                    if ($as = "target") then
                        "{target.source: {$regex: '" || $resource-uuid || "'}},
                        {target.id: {$regex: '" || $resource-uuid || "'}}"
                    else 
                        ()
                    ,
                    if ($as = "body") then
                        "{body.id: {$regex: '" || $resource-uuid || "'}}"
                    else ()
                )
    
        let $query := 
                "{
                    $or: [" || string-join($or-query-substrings, ",") || "]
                }"
                
(:        let $log := util:log("INFO", $query) :)
        let $return := mongodb:find($hra-anno-framework:mongodbClientId, $config:mongo-database, $config:mongo-anno-collection, $query, "{'_id': 0}")
(:        let $log := util:log("INFO", $return) :)

        let $return := 
            if ($json) then 
                array{
                    for $anno in $return
                    return
                        parse-json($anno)
                }
            else
                $return
        return
            $return
    } catch * {
        let $log := util:log("ERROR", "Error: getting annotations failed with exception: " ||  $err:code || ": " || $err:description)
        return
            error($hra-anno-framework:MONGODB-ERROR, "Deleting failed!")

    }
};

declare function hra-anno-framework:delete-annotation($anno-id) {
    try {
        let $criterium := "{'id': '" || $anno-id || "'}, {justOne: true}"
        let $delete-result := mongodb:remove($hra-anno-framework:mongodbClientId, $config:mongo-database, $config:mongo-anno-collection, $criterium)
        return 
            $delete-result
    } catch * {
        error($hra-anno-framework:MONGODB-ERROR, "Deleting failed!")
    }
};

declare function hra-anno-framework:serialize-annotations($annos-json-array as array(*), $output-target as xs:string) {
    <div class="resourceTargets">
        {
            let $config-collection := collection("/db/data/tamboti")

            (: get unique resourceIDs (occured in source as well of target as of body :)
            let $resourceIds := distinct-values(for $iri in ($annos-json-array?*?body?source, $annos-json-array?*?target?source) return functx:substring-after-last($iri, "/"))
            let $resources := <resources>{security:get-resources($resourceIds)}</resources>
            
            let $serialized-targets :=
                <targets>
                    {
                        array:for-each($annos-json-array, function($anno-map){
                            let $target-id := functx:substring-after-last($anno-map?target?source, "/")
                            let $body-id := functx:substring-after-last($anno-map?body?source, "/")
            
                            let $render-definition := $anno-map?body?renderedVia
                            let $url-template := $anno-map?body?renderedVia?('schema:urlTemplate')

                            let $config-definition := functx:substring-after-last($url-template, "/")

                            let $anno-type-id := substring-after($config-definition, "#")
                            let $anno-config-id := substring-before($config-definition, "#")
                            let $config-file := $config-collection/c:annoconfig[@xml:id=$anno-config-id]
                            let $serialize-definitions := $config-file/c:annotation[@id=$anno-type-id]/c:serializations
                
                            let $target-selector := $anno-map?target?selector?value
                            let $body-selector := $anno-map?body?selector?value
                
                            let $target-xml := $resources/*[@ID = $target-id or @xml:id = $target-id or @id = $target-id]
                            let $body-xml := $resources/*[@ID = $body-id or @xml:id = $body-id or @id = $body-id]
        
                            let $anno-id := $anno-map?id
                            let $anno-api-uri := $hra-anno-framework:tamboti-api-root || "annotation/"
                            
                            return 
        
            (:                let $log := util:log("INFO", $target-xml):)
            (:                (: if either body or target is not accessible, put out the "non accessible" placeholder:):)
                                if (not($target-xml) or not($body-xml)) then
                                    $hra-anno-framework:inaccessible-target-html
                                else
                                    <target annoId="{$anno-id}" resourceId="{$body-id}" resourceSelector="{$body-selector}" annoConfigId="{$anno-config-id}" annoTypeId="{$anno-type-id}" targetId="{$target-id}" targetSelector="{$target-selector}">
                                        {
                                            util:eval($serialize-definitions/c:serialize[@output-target=$output-target])
                                        }
                                    </target>
                        })
                    }
                </targets>

            return
                for $targetTypes in $serialized-targets/target
                group by $resourceId := $targetTypes/@resourceId
                    return
                        <div class="resource">
                            <div class="id">{$resourceId/string()}</div>
                            <div class="label"/>
                            <div class="targets">
                                {
                                    for $targetType in $targetTypes
                                    let $annoConfigId := $targetType/@annoConfigId/string()
                                    return
                                        for $targetBlocks in $targetType
                                            let $annoTypeId := $targetBlocks/@annoTypeId
                                            let $config-file := $config-collection/id($annoConfigId)
                                            let $annoType-definition := $config-file/c:annotation[@id=$annoTypeId]
                
                                            return
                                                <div class="target">
                                                    <div class="id">{$annoTypeId/string()}</div>
                                                    <div class="configId">{$annoConfigId}</div>
                                                    <div class="label">{$annoType-definition/c:label/string()}</div>
                                                    <div class="description">{$annoType-definition/c:description/string()}</div>
                                                    <div class="validDrop"></div>
                                                    <div class="targetBlocks">
                                                    {
                                                        for $targetBlock in $targetBlocks
                                                        return
                                                          <div class="targetBlock" data-annoId="{$targetBlock/@annoId/string()}" data-svgId="{$targetBlock/@targetId/string()}" data-targetSelector="{$targetBlock/@targetSelector/string()}" data-annoTypeId="{$annoTypeId/string()}" data-annoConfigId="{$annoConfigId}">
                                                            <div class="resourceSelector">{$targetBlock/@resourceSelector/string()}</div>
                                                                {
                                                                    $targetBlock/div/div[@class=("label", "short", "detail", "footer")]
                                                                }
                                                            </div>
                                                    }
                                                    </div>
                                                </div>
                                }
                            </div>
                        </div>
(:                    $target:)
(:                    <div class="resource">:)
        }
    </div>

(:    let $render-definition := $anno-map?target?renderedVia:)
(:    return $render-definition:)
    
    
};


declare function hra-anno-framework:as-target($resource-uuid as xs:string){
(:    let $log := util:log("INFO", "resid: " || $resource-uuid):)
    let $query := 
        "{
            $or: [{target.source: '" || $resource-uuid || "'},
                {target.id: '" || $resource-uuid || "'}]
        }"

    let $annotation := mongodb:find($hra-anno-framework:mongodbClientId, $config:mongo-database, $config:mongo-anno-collection, $query, "{_id: 0}")
    return
        $annotation
};

declare function hra-anno-framework:as-body($resource-uuid as xs:string){
    let $annotation := mongodb:find($hra-anno-framework:mongodbClientId, $config:mongo-database, $config:mongo-anno-collection, "{body.id: '" || $resource-uuid || "'}}", "{'_id': 0}")
    return
        $annotation
};

declare function hra-anno-framework:store-annotations($annotations as node(), $stringOutput as xs:boolean?){
(:    try {:)
    <div class="annoStoreResults">
        {
            for $annotationConfig in $annotations/div[@class="annotations"]/div
            group by $configId := $annotationConfig/@data-configid
                let $config := collection("/db/data/tamboti/")/c:annoconfig[@xml:id = $configId]
                return
        (:            <configType id="{$configId}">:)
                    for $annotationType in $annotationConfig
                    group by $annoTypeId := $annotationType/@data-targettypeid
                        let $anno-def := $config/c:annotation[@id = $annoTypeId]
                        let $serialization-query := $anno-def//c:generateAnnotation/c:query
                        let $html := $annotationType
                        return
                            for $annoHtml in $annotationType
                            let $annoContainerId := $annoHtml/@data-annocontainerid/string()
                            return
                                try {
                                    (: Should anno get deleted? :)
                                    if($annoHtml/@data-delete/string() = "true") then
                                        let $annoId := $annoHtml/@data-annoid/string()
                                        let $delete := hra-anno-framework:delete-annotation($annoId)
                                        return
                                            <div class="return" id="{$annoContainerId}" success="true" new="false" annoId="{$annoId}">Annotation successfully saved</div>
                                    else
                                        
                                        let $anno-map := util:eval($serialization-query)
                                        return
                                            (: successfully serialized annotation? :)
                                            (: new anno :)
                                            if ($annoHtml/@data-annoid) then
                                                let $anno-map := map:new((
                                                    $anno-map,
                                                    map:entry("id", $annoHtml/@data-annoid/string())
                                                ))
                                                return
                                                    if (not($stringOutput)) then
                                                        let $stored-anno-id := hra-anno-framework:save-annotation($anno-map)
                                                        return
                                                            <div class="return" id="{$annoContainerId}" success="true" new="false" annoId="{$stored-anno-id}">Annotation successfully saved</div>
                                                    else
                                                        serialize($anno-map, $hra-anno-framework:json-serialize-parameters)
        
                                            (: update anno :)
                                            else
                                                if (not($stringOutput)) then
                                                    let $annoId := $hra-anno-framework:tamboti-api-root || "annotation/anno-" || util:uuid()
                                                    let $anno-map := map:new((
                                                        $anno-map,
                                                        map:entry("id", $annoId)
                                                    ))
                                                    let $stored-anno-id := hra-anno-framework:save-annotation($anno-map)
                                                    return
                                                        <div class="return" id="{$annoContainerId}" success="true" new="true" annoId="{$stored-anno-id}">Annotation successfully saved</div>
                                                else
                                                    serialize($anno-map, $hra-anno-framework:json-serialize-parameters)
        
                                    } catch hra-anno-framework:mongodb-error {
                                        <div class="return" id="{$annoContainerId}" success="false">{$err:code}: {$err:description}</div>
                                    } catch * {
                                        let $log := util:log("ERROR", "EXCEPTION: " || $err:code || ":" || $err:description)
                                        return
                                            <div class="return" id="{$annoContainerId}" success="false">{$err:code || ":" || $err:description}</div>
                                    }
        }
    </div>
};

declare function hra-anno-framework:get-annotation-nodes($json-map as map(*)) {
    let $url-template := $json-map?body?renderedVia?('schema:urlTemplate')
    let $config-collection := collection("/db/data/tamboti")
    let $config-definition := functx:substring-after-last($url-template, "/")
    let $anno-type-id := substring-after($config-definition, "#")
    let $anno-config-id := substring-before($config-definition, "#")
    
    let $config-file := $config-collection/c:annoconfig[@xml:id=$anno-config-id]
    let $serialize-definitions := $config-file/c:annotation[@id=$anno-type-id]/c:serializations

    let $target-id := functx:substring-after-last($json-map?target?source, "/")
    let $body-id := functx:substring-after-last($json-map?body?source, "/")
    
    let $target-selector := $json-map?target?selector?value
    let $body-selector := $json-map?body?selector?value

    let $target-xml := security:get-resource($target-id)
    let $body-xml := security:get-resource($body-id)

    let $namespaces := hra-anno-framework:bind-namespaces($target-xml)
    
    let $target-xml-node := util:eval("root($target-xml)" || $target-selector)
    (: unbind the namespaces again to avoid conflicts with body namespace definitions:)
    let $unbind := 
        if ($target-xml) then
            hra-anno-framework:unbind-in-scope-namespaces($target-xml)
        else
            ()

    let $namespaces := hra-anno-framework:bind-namespaces($body-xml)
    let $body-xml-node := util:eval("root($body-xml)" || $body-selector)

    let $unbind := 
        if ($body-xml) then
            hra-anno-framework:unbind-in-scope-namespaces($body-xml) 
        else
            ()
    return
        map{
            "annoInfos": map{
                "full": $json-map,
                "config-id": $anno-config-id,
                "annotype-id": $anno-type-id
            },
            "annoId": $json-map?('id'),
            "serialize-definitions": $serialize-definitions,
            "target": map{
                "iri" : $json-map?target?source,
                "uuid" := $target-id,
                "selector" := $target-selector,
                "xml-full" := $target-xml,
                "xml-node" := $target-xml-node
            },
            "body": map{
                "iri" := $json-map?body?source,
                "uuid" := $body-id,
                "selector" := $body-selector,
                "xml-full" := $body-xml,
                "xml-node" := $body-xml-node
            }
        }
};

declare function hra-anno-framework:bind-namespaces($xmls as node()*) {
    for $xml in $xmls
        return
            for $prefix in in-scope-prefixes($xml)
                let $uri := namespace-uri-for-prefix($prefix, $xml)
                let $log := util:log("INFO", $prefix || " -> " || $uri)
                return
                    if($prefix = "xml") then
                        ()
                    else
                        util:declare-namespace($prefix, $uri)

};

declare function hra-anno-framework:unbind-in-scope-namespaces($xml as node()) {
    for $prefix in in-scope-prefixes($xml)
        let $uri := namespace-uri-for-prefix($prefix, $xml)
        return
            if($prefix = "xml") then
                ()
            else
                util:declare-namespace($prefix, xs:anyURI(""))

};

declare function hra-anno-framework:get-annotator-targets($resource-uuid as xs:string, $anno-config-id as xs:string) {
    let $anno-config := hra-anno-framework:get-annotator-config($anno-config-id)
(:    let $log := util:log("INFO", "anno-cfg-id " || $anno-config-id):)

    let $xml := root(security:get-resource($resource-uuid))
    return
        if(not($xml)) then
            <div/>
        else
            <div class="resourceTargets">
                <div class="resource">
                    <div class="id">{$resource-uuid}</div>
                    <div class="label">
                        <a href="{$hra-anno-framework:tamboti-root}modules/search/index.html?search-field=ID&amp;value={$resource-uuid}" target="_blank">Tamboti Resource {$resource-uuid}</a>
                    </div>
                    <div class="targets">
                        {
                            (: apply each annotation target query on resource  :)
                            for $annotation in $anno-config/c:annotation
                                let $id := $annotation/@id/string()
                                let $valid-nodes-xpath := $annotation/c:bodies/c:body[1]/c:selector/string()
        (:                        let $log := util:log("INFO", $valid-nodes-xpath):)
                                return
                                    <div class="target">
                                        <div class="id">{$id}</div>
                                        <div class="configId">{$anno-config-id}</div>
                                        <div class="label">{$annotation/c:label/string()}</div>
                                        <div class="description">{$annotation/c:description/string()}</div>
                                        <div class="validDrop">{$valid-nodes-xpath}</div>
                                        <div class="targetBlocks">
                                            {
                                                for $target-def in $annotation/c:targets/c:target
                                                    let $target-type := $target-def/@id/string()
            (:                                        try {:)
                                                    let $eval-string := $target-def/c:displayHint/c:query/string()
                                                    let $results := util:eval($eval-string)
                                                    return
                                                        for $resultDiv in $results
                                                            let $xpath := $resultDiv/div[@class="resourceSelector"]/string()
                                                            (: if somehow no xpath is returned an annotation will not be possible -> omit this result:)
                                                            return
                                                                if ($xpath) then
                                                                    $resultDiv
                                                                else
                                                                    ()

                (:                                        } catch * {:)
                (:                                            let $log := util:log("ERROR", "Error: getting annotations failed with exception: " ||  $err:code || ": " || $err:description):)
                (:                                            return :)
                (:                                                () :)
                (:                                        }:)
                                            }
                                        </div>
                                    </div>
                        }
                    </div>
                </div>                        
            </div>
};

(:~
 : get all available Annotator configurations
 :)

declare function hra-anno-framework:get-annotator-configs() {
    let $col := collection("/db/data/tamboti")
    return
        $col//c:annoconfig
};

declare function hra-anno-framework:get-annotator-config($config-id as xs:string) {
    let $col := collection("/db/data/tamboti")
    return
        $col//c:annoconfig[@xml:id=$config-id]
};

declare function hra-anno-framework:get-callbacks($config-id as xs:string, $anno-type-id as xs:string) {
    let $anno-config := hra-anno-framework:get-annotator-config($config-id)
    return $anno-config//c:annotation[@id = $anno-type-id]/c:callbacks/string()
    
};