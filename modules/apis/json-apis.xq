xquery version "3.1";

declare namespace json-apis = "http://hra.uni-heidelberg.de/ns/tamboti/apis/json";
declare namespace anno-config = "http://hra.uni-heidelberg.de/ns/tamboti/annotations/config";
declare namespace json="http://www.json.org";
declare namespace xhtml="http://www.w3.org/1999/xhtml";

import module namespace hra-rdf-framework = "http://hra.uni-heidelberg.de/ns/hra-rdf-framework" at "../../frameworks/hra-rdf/hra-rdf-framework.xqm";
import module namespace hra-anno-framework = "http://hra.uni-heidelberg.de/ns/hra-anno-framework" at "../../frameworks/hra-annotations/hra-annotations.xqm";

declare variable $json-apis:json-serialize-parameters :=
    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
        <output:method value="json"/>
        <output:media-type value="text/javascript"/>
    </output:serialization-parameters>;


declare function json-apis:get($method as xs:string, $scope as xs:string, $parameters as xs:string*, $query-string as xs:string?) {
    switch($scope)
(:        case "targets" return:)
(:            json-apis:targets($parameters):)
        case "annotationConfigs" return
            json-apis:annotation-configs()
(:        case "annotations" return:)
(:            json-apis:get-annotations($parameters):)
        default return
            () 
};

declare function json-apis:post($method as xs:string, $scope as xs:string, $parameters as xs:string*, $query-string as xs:string?) {
    switch($scope)
        case "canvas" return
            let $result := json-apis:newCanvas($parameters)
(:            let $log := util:log("INFO", $result):)
            return
                if($result) then
                    map {"uuid": $result}
                else 
                    response:set-status-code(500)
        case "annotation" return
(:            let $log := util:log("INFO", $post-data/div/@data-configid/string()):)
(:            return:)
                try {
                    util:eval(xs:anyURI("../../frameworks/hra-annotations/annotations.xq"), false(), (("action", "store"), ("data", request:get-data())))
                } catch * {
                    <root json:literal="false" />
                }

        default return
            () 
};


declare function json-apis:newCanvas($parameters as xs:string*) {
    let $saveCanvas :=  hra-rdf-framework:saveCanvas(request:get-header("T-image-uuid"), request:get-header("T-svg-uuid"), request:get-header("T-canvasAnno-uuid"))
    return
        $saveCanvas
(:        <root json:literal="true">{request:get-header("T-canvasAnno-uuid")}</root>:)
};

declare function json-apis:annotation-configs() {
    let $annotationConfigs := hra-anno-framework:get-annotator-configs()
    let $json :=
        array {
            for $config in $annotationConfigs
                return
                    map {
                        "id": $config/@xml:id/string(),
                        "label": $config/anno-config:label/string(),
                        "description": $config/anno-config:description/string(),
                        "tooltip": $config/anno-config:target-api-tooltip/string(),
                        "annotations" :
                            array {
                                for $anno in $config/anno-config:annotation 
                                return
                                        map{
                                            "bodies": 
                                                array {
                                                    for $body in $anno/anno-config:bodies/anno-config:body
                                                        return
                                                            map{
                                                                "label": $body/anno-config:label/string(),
                                                                "namespaces": 
                                                                    for $ns in $body/anno-config:qnames/anno-config:qname
                                                                    return
                                                                        map {
                                                                            $ns/@prefix/string() : $ns/string()
                                                                        },
                                                                "selector": $body/anno-config:selector/string() 
                                                                
                                                            }
                                                    }
                                            ,
                                            "id": $anno/anno-config:identifier/string(),
                                            "label": $anno/anno-config:label/string(),
                                            "description": $anno/anno-config:description/string()
                                    }
                            }
                    }
        }
    return
        $json
};

(:declare function json-apis:get-annotations($parameters) {:)
(:    util:eval(xs:anyURI("../../frameworks/hra-annotations/annotations.xq"), false(), ((xs:QName("action"), "as-body-or-target"), (xs:QName("iri"), xmldb:decode-uri($parameters[1])))):)
(::)
(:};:)

(:declare function json-apis:targets($parameters) {:)
(:    let $anno-config-id := request:get-parameter("annoConfigId", ()):)
(:    let $annotations := hra-rdf-framework:get-annotator-targets($parameters[1], $anno-config-id):)
(:    let $json :=:)
(:        map { "annotations" ::)
(:                for $anno in $annotations/annotation:)
(:                    return:)
(:                        map {:)
(:                            "label": $anno/label/string(),:)
(:                            "description": $anno/description/string(),:)
(:                            "id": $anno/identifier/string(),:)
(:                            "blocks"::)
(:                                if (count($anno//displayBlocks/block) = 1) then:)
(:                                    let $block := $anno//displayBlocks/block:)
(:                                    return:)
(:                                        [:)
(:                                            map {:)
(:                                                "iri": $block/iri/string(),:)
(:                                                "label": serialize($block//xhtml:div[@class="target-label"]),:)
(:                                                "short": serialize($block//xhtml:div[@class="target-short"]),:)
(:                                                "detail": serialize($block//xhtml:div[@class="target-detail"]),:)
(:                                                "footer": serialize($block//xhtml:div[@class="target-footer"]):)
(:                                            }:)
(:                                        ]:)
(:                                else:)
(:                                    for $block in $anno//displayBlocks/block:)
(:                                        return:)
(:                                            map {:)
(:                                                "iri": $block/iri/string(),:)
(:                                                "label": serialize($block//xhtml:div[@class="target-label"]),:)
(:                                                "short": serialize($block//xhtml:div[@class="target-short"]),:)
(:                                                "detail": serialize($block//xhtml:div[@class="target-detail"]),:)
(:                                                "footer": serialize($block//xhtml:div[@class="target-footer"]):)
(:                                            }:)
(:                    }:)
(:        }:)
(::)
(:    return:)
(:        $json:)
(::)
(:};:)

let $method := request:get-method()
(:let $log := util:log("INFO", request:get-uri()):)

let $path := substring-after(request:get-uri(), "/api/")
let $tokenized-path := tokenize($path, "/")

let $scope := $tokenized-path[1]

let $query-string := request:get-query-string()
let $query-string := 
    if($query-string) then 
        xmldb:decode($query-string)
    else
        ""
let $parameters := subsequence($tokenized-path, 2)

let $header := response:set-header("Content-Type", "application/json")
let $cors := 
    (
        response:set-header("Access-Control-Allow-Origin", "*"),
        response:set-header("Access-Control-Allow-Methods", "OPTIONS, GET, POST, PUT"),
        response:set-header("Access-Control-Allow-Headers", "_authToken, content-type, X-Custom-Header, user-agent, T-image-uuid, T-svg-uuid, T-canvasAnno-uuid")
    )

return
 switch($method)
    case "GET"
    return
        serialize(json-apis:get($method, $scope, $parameters, $query-string), $json-apis:json-serialize-parameters)
    case "POST"
    return
        serialize(json-apis:post($method, $scope, $parameters, $query-string), $json-apis:json-serialize-parameters)
    default return 
        ()    
