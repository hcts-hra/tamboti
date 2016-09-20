xquery version "3.0";

import module namespace functx="http://www.functx.com";
import module namespace tamboti-security = "http://exist-db.org/mods/security" at "../../modules/search/security.xqm";

declare namespace cfg="http://hra.uni-heidelberg.de/ns/tamboti/annotations/config";
declare namespace json="http://www.json.org";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

declare variable $local:json-serialize-parameters :=
                
    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
    <output:method value="json"/>
    <output:media-type value="text/javascript"/>
    </output:serialization-parameters>;


declare function local:load-namespaces($qnames as node()) {
    for $qname in $qnames/cfg:qname
    return
        util:declare-namespace($qname/@prefix, xs:anyURI($qname/string()))
};

declare function local:process-displayHint($nodes as node()*, $var-map as map()) {
    for $node in $nodes
    return 
        typeswitch($node)
            case element() return
                let $data-name := $node/@data-name
                let $data-query := $node/@data-query
                let $data-root := $node/@data-root
                let $classes := $node/@class
(:                let $element-xquery := :)
(:                    if ($data-root="xml") then:)
(:                        $var-map($data-root/string()):)
(:                    else:)
(:                        ():)
(:                :)
                        
                (: if a data-query is set, evaluate it:)
                return 
                    if ($data-query) then
                        let $data := util:eval("$var-map($data-root/string())" || $data-query/string())
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
                            let $xpath := 
(:                                if (not($d instance of xs:string)) then:)
                                if ($data-root="xml") then
                                    let $log := util:log("INFO", $var-map("root-iri"))
                                    let $log := util:log("INFO", $var-map("root-iri") || "/" || functx:path-to-node-with-pos($d))
                                    return
                                    functx:path-to-node-with-pos($d)
                                else
                                    ()
                                    
        
(:                        let $log := util:log("INFO", $data-name):)
(:                        let $log := util:log("INFO", functx:atomic-type($data)):)
(:                        let $log := util:log("INFO", $data):)
(:                let $data := :)

                    return
(:                        element { fn:node-name($node) } {:)
(:                            ($node/@*[not(starts-with(local-name(), "data-"))], :)
(:                                attribute target-index {$idx},:)
(:                                if($xpath) then attribute xpath {$xpath} else (),:)
(:                                $output),:)
(:                            $node/node() ! local:process-displayHint(., $var-map):)
(:                        }:)
                        element { fn:node-name($node) } {
                            ($node/@*[not(starts-with(local-name(), "data-"))], $output),
                            $node/node() ! local:process-displayHint(., $var-map)
                        }
                else
                    element { fn:node-name($node) } {
                        ($node/@*[not(starts-with(local-name(), "data-"))]), $node/node() ! local:process-displayHint(., $var-map)}

            default return 
                $node

};

let $config := doc("/db/data/tamboti/retrodig-config.xml")

let $uuid := request:get-parameter("uuid", "w_8105322d-67f2-42d6-9b80-226a378ac6c7")

let $resource := doc(xmldb:encode-uri("/data/users/matthias.guth@ad.uni-heidelberg.de/GrabungKMHKastellweg/Grabungstagebuch/w_8105322d-67f2-42d6-9b80-226a378ac6c7.xml"))

let $targets := $config/cfg:annoconfig/cfg:annotation/cfg:targets
let $target := $targets/cfg:target[1]

let $root-iri := request:get-scheme() || "://" || request:get-server-name() || (if (request:get-server-port() = 80) then "" else ":" || request:get-server-port()) || "/exist/apps/tamboti/resource/" || $uuid

let $var-map := 
    map:new(
        (
            map:entry("namespace-nodes", $target/cfg:qnames)
            ,
            map:entry("xml", $resource)
            ,
            map:entry("root-iri", $root-iri)
        )
    )

let $load-namespaces := local:load-namespaces($target/cfg:qnames)
let $json-xml := local:process-displayHint($target/cfg:displayHint/*, $var-map)
(:let $header := response:set-header("Content-Type", "application/json"):)
return
    <html>
        <head>
            <style>
                .target-root &#x7B; 
                    border: 1px solid green; 
                    margin : 5px;
                    background-color: #DBF6FF;
                &#x7D;
                .target-title &#x7B; 
                    border: 1px solid black;
                    padding: 1em;
                &#x7D;
                .target-short &#x7B; 
                    padding: 1em;
                    border: 1px solid yellow; 
                &#x7D;
                .target-detail &#x7B;
                    padding: 1em;
                    border: 1px solid blue;
                &#x7D;
            </style>
        </head>
        <body>
            <div style="width:200px">
            {
                $json-xml
            }
            </div>
        </body>
    </html>

