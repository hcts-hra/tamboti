xquery version "3.1";

module namespace hra-anno-framework = "http://hra.uni-heidelberg.de/ns/hra-anno-framework";

import module namespace mongodb="http://expath.org/ns/mongo" at "java:org.exist.mongodb.xquery.MongodbModule";
import module namespace functx="http://www.functx.com";
import module namespace security = "http://exist-db.org/mods/security" at "/apps/tamboti/modules/search/security.xqm";

declare namespace c="http://hra.uni-heidelberg.de/ns/tamboti/annotations/config";
declare namespace xhtml="http://www.w3.org/1999/xhtml";

declare variable $hra-anno-framework:mongo-url := "mongodb://localhost";
declare variable $hra-anno-framework:mongo-database := "tamboti-test";
declare variable $hra-anno-framework:mongo-anno-collection := "annotations";
declare variable $hra-anno-framework:mongodbClientId := mongodb:connect($hra-anno-framework:mongo-url);

declare variable $hra-anno-framework:json-serialize-parameters :=
    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
        <output:method value="json"/>
        <output:media-type value="text/javascript"/>
    </output:serialization-parameters>;


declare function hra-anno-framework:save-annotation($annotations-map as map(*)) {
    (: connect to mongodb :)

    (: first look for existence of the annotation-id in mongodb  :)
    let $anno-id := $annotations-map?("id")
    let $found := mongodb:find($hra-anno-framework:mongodbClientId, $hra-anno-framework:mongo-database, $hra-anno-framework:mongo-anno-collection, "{'id': '" || $anno-id || "'}")

    let $log := util:log("INFO", "{'id': '" || $anno-id || "'}")
    let $log := util:log("INFO", $found)
    let $anno-json := serialize($annotations-map, $hra-anno-framework:json-serialize-parameters)
    let $result := 
        if ($found) then
            mongodb:update($hra-anno-framework:mongodbClientId, $hra-anno-framework:mongo-database, $hra-anno-framework:mongo-anno-collection, "{'id': '" || $anno-id || "'}", $anno-json, true(), false())
        else
            mongodb:insert($hra-anno-framework:mongodbClientId, $hra-anno-framework:mongo-database, $hra-anno-framework:mongo-anno-collection, $anno-json)

(:    :)
(:    let $config := hra-anno-framework:get-annotator-config($anno-config-id):)
(:    let $target-definition := $config//anno-config:targets[$anno-type-idx]:)
    
    return
        $anno-id
(:        $found:)
(:        ( :)
(:            util:log("INFO", $config), :)
(:            util:log("INFO", $annotations-map):)
(:        ) :)
(:        util:log("INFO", $anno-xml):)

};

declare function hra-anno-framework:get-annotation($anno-id as xs:string){
    let $annotation := mongodb:find($hra-anno-framework:mongodbClientId, $hra-anno-framework:mongo-database, $hra-anno-framework:mongo-anno-collection, "{'id': '" || $anno-id || "'}", "{_id: 0}")
    return
        $annotation

};

declare function hra-anno-framework:get-annotations($resource-uuid as xs:string, $as as xs:string*, $json as xs:boolean?) {
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
        let $log := util:log("INFO", $query)
        let $return := mongodb:find($hra-anno-framework:mongodbClientId, $hra-anno-framework:mongo-database, $hra-anno-framework:mongo-anno-collection, $query, "{'_id': 0}")
        let $log := util:log("INFO", $return)

        let $return := 
            if ($json) then 
                parse-json($return)
            else
                $return
        return
            $return
    } catch * {
        let $log := util:log("ERROR", "Error: getting annotations failed with exception: " ||  $err:code || ": " || $err:description)
        return
            false()
    }
};

(:declare function hra-anno-framework:parse-anno-to-display($anno-map as map(*)) {:)
(:    let $render-definition := $anno-map?target?renderedVia:)
(:    return $render-definition:)
(:};:)


declare function hra-anno-framework:as-target($resource-uuid as xs:string){
(:    let $log := util:log("INFO", "resid: " || $resource-uuid):)
    let $query := 
        "{
            $or: [
                {target.source: '" || $resource-uuid || "'},
                {target.id: '" || $resource-uuid || "'}
                ]
        }"
                
    let $annotation := mongodb:find($hra-anno-framework:mongodbClientId, $hra-anno-framework:mongo-database, $hra-anno-framework:mongo-anno-collection, $query, "{_id: 0}")
    return
        $annotation
};

declare function hra-anno-framework:as-body($resource-uuid as xs:string){
    let $annotation := mongodb:find($hra-anno-framework:mongodbClientId, $hra-anno-framework:mongo-database, $hra-anno-framework:mongo-anno-collection, "{body.id: '" || $resource-uuid || "'}}", "{'_id': 0}")
    return
        $annotation
};

declare function hra-anno-framework:generate-anno($html as node(), $anno-config-id as xs:string, $target-id as xs:string) as map(*)?{
    try {
        let $config := collection("/db/data/tamboti/")/c:annoconfig[@xml:id = $anno-config-id]
        let $target-query := $config//c:target[$target-id]/c:generateAnnotation/c:query
        let $json-map := util:eval($target-query/string())
        return
            $json-map
    } catch * {
        let $log := util:log("ERROR", "Error: adding annotation failed with exception: " ||  $err:code || ": " || $err:description)
        return
            false()
    }
};

declare function hra-anno-framework:get-annotation-nodes($json-map as map(*)) {
    let $url-template := $json-map?target?renderedVia?('schema:urlTemplate')
    let $config-collection := collection("/db/data/tamboti")
    let $config-definition := functx:substring-after-last($url-template, "/")
    let $target-id := substring-after($config-definition, "#")
    let $anno-config-id := substring-before($config-definition, "#")
    
    let $config-file := $config-collection/c:annoconfig[@xml:id=$anno-config-id]
    let $target-definition := $config-file/c:annotation/c:targets/c:target[@id=$target-id]
(:    let $serialization-script := $target-definition/c:serializations/c:serialize[@output-target="canvas-editor"]/string():)
    
    let $target-id := functx:substring-after-last($json-map?target?source, "/")
    let $body-id := functx:substring-after-last($json-map?body?source, "/")
    
    let $target-selector := $json-map?target?selector?value
    let $body-selector := $json-map?body?selector?value

    let $target-xml := security:get-resource($target-id)
    let $body-xml := security:get-resource($body-id)

    let $configfile-namespaces := 
        for $namespace in $target-definition/c:qnames/c:qname
            let $prefix := $namespace/@prefix/string()
            return
                if($prefix = "xml") then
                    ()
                else
                    util:declare-namespace($prefix, xs:anyURI($namespace/string()))

    let $namespaces := hra-anno-framework:bind-namespaces($target-xml)

(:    let $log := util:log("INFO", in-scope-prefixes(util:eval()):)
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
            "annoId" : $json-map?('id'),
            "target-definition": $target-definition,
            "target": map{
                "iri" := $json-map?target?source,
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
    let $qnames := 
        map:merge((
                for $xml in $xmls
                    return
                        (
                        for $prefix in in-scope-prefixes($xml)
                            let $uri := namespace-uri-for-prefix($prefix, $xml)
                            return
                                map:entry($prefix, $uri)
                        )
(:                    ,:)
(:                    for $namespace in $data?('target-definition')/c:qnames/c:qname:)
(:                        let $prefix := $namespace/@prefix/string():)
(:                        return:)
(:                            map:entry($prefix, xs:anyURI($namespace/string())):)
        ))

    return
        map:for-each($qnames, function ($prefix, $uri) {
            if($prefix = "xml") then
                ()
            else
                (
                util:declare-namespace($prefix, $uri)
                )
        })
};

declare function hra-anno-framework:eval-as-target($data as map(*), $output-target as xs:string) {
(:    let $log := util:log("INFO", map:keys($data?target)):)
(:    let $log := util:log("INFO", $data?target?('xml-full')):)
(:    return:)
        if($data?target?('xml-full') or $data?body?('xml-full')) then
            (
            hra-anno-framework:bind-namespaces(($data?target?('xml-full'), $data?body?('xml-full'))),
            util:eval($data?('target-definition')/c:serializations/c:serialize[@output-target=$output-target])
            )
        else
            ()
    
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

declare function hra-anno-framework:process-displayHint($nodes as node()*, $var-map as map()) {
    for $node in $nodes
    return 
        typeswitch($node)
            case element() return
                let $data-name := $node/@data-name
                let $data-query := $node/@data-query
                let $data-query-type := $node/@data-query-type
                let $data-root := $node/@data-root
                let $classes := $node/@class
                let $node-data := $node/string()
                (: if a data-query is set, evaluate it:)
                return 
                    switch ($data-query-type)
                        case "xpath" return
                            let $query-string := "$var-map($data-root/string())" || $data-query/string()
                            let $data := util:eval($query-string)
                            for $d at $idx in $data
                                let $var-map :=
                                    if ($data-query) then
                                        map:put($var-map, $data-name/string(), $d)
                                    else
                                        $var-map
        
                                let $output := 
                                    if ($d instance of xs:string) then
                                        $d
                                    else
                                        ""
                                let $node-iri := 
                                    if ($data-root="xml") then
    (:                                    let $log := util:log("INFO", $var-map("root-iri")):)
    (:                                    let $log := util:log("INFO", $var-map("root-iri") || "?" || functx:path-to-node-with-pos($d)):)
    (:                                    return:)
                                            $var-map("root-iri") || "?" || xmldb:encode-uri($data-query/string() || "[" || $idx || "]")
                                    else
                                        ()
                        return
                            element { fn:node-name($node) } {
                                ($node/@*[not(starts-with(local-name(), "data-"))]
                                ,
                                if ($node-iri) then
                                    attribute node-iri {$node-iri}
                                else
                                    ()
                                ,
                                $output),
                                $node/node() ! hra-anno-framework:process-displayHint(., $var-map)
                            }
                    case "xquery" return
                        let $context := 
                            <static-context>
                                <variable name="xml">{$var-map('xml')}</variable>
                            </static-context>
(:                        let $log := util:log("INFO", $node-data):)
                        let $result := util:eval($node-data)
(:                        let $log := util:log("INFO", $result):)
                        return
                            element { fn:node-name($node) } {
                                ($node/@*[not(starts-with(local-name(), "data-"))]
                                ,
                                $result),
                                $node/node()[position() > 1] ! hra-anno-framework:process-displayHint(., $var-map)
                            }

                            
                    default return
                        element { fn:node-name($node) } {
                            ($node/@*[not(starts-with(local-name(), "data-"))]), $node/node() ! hra-anno-framework:process-displayHint(., $var-map)}

            default return 
                $node

};

declare function hra-anno-framework:get-annotator-targets($resource-uuid as xs:string, $anno-config-id as xs:string) {
    let $anno-config := hra-rdf-framework:get-annotator-config($anno-config-id)
    let $resource-xml := root(tamboti-security:get-resource($resource-uuid))

    let $root-iri := request:get-scheme() || "://" || request:get-server-name() || (if (request:get-server-port() = 80) then "" else ":" || request:get-server-port()) || "/exist/apps/tamboti/api/resource/" || $resource-uuid
    
    let $annotationTargets :=
        for $anno in $anno-config/cfg:annotation
            return
                <annotation>
                    <identifier>{$anno/cfg:identifier/string()}</identifier>
                    <label>{$anno/cfg:label/string()}</label>
                    <description>{$anno/cfg:description/string()}</description>
                    {
                        for $target in $anno/cfg:targets/cfg:target
                            let $var-map := 
                                map:new( 
                                    ( 
                                        map:entry("namespace-nodes", $target/cfg:qnames)
                                        ,
                                        map:entry("xml", $resource-xml)
                                        ,
                                        map:entry("root-iri", $root-iri)
                                    )
                                )
                            
                            let $load-namespaces := hra-anno-framework:bind-namespaces($resource-xml)
                            let $display-blocks := hra-anno-framework:process-displayHint($target/cfg:displayHint/*, $var-map)
                            return
                                <target>
                                    <id>{$target/@id/string()}</id>
                                    <label>{$target/cfg:label/string()}</label>
                                    <displayBlocks>
                                        {
                                            for $block in $display-blocks
(:                                            let $log := util:log("INFO", functx:change-element-ns-deep($block, "", "")):)
                                            return
                                                <block>
                                                    <iri>{$block/@node-iri/string()}</iri>
                                                    {
                                                        $block
                                                    }
                                                </block>
                                        }
                                    </displayBlocks>
                                </target>
                    }
                </annotation>
    
    return
        <annotationTargets>
            {$annotationTargets}
        </annotationTargets>
        
};
