xquery version "3.1";

module namespace apis = "http://hra.uni-heidelberg.de/ns/tamboti/apis/";
import module namespace hra-rdf-framework = "http://hra.uni-heidelberg.de/ns/hra-rdf-framework" at "../../frameworks/hra-rdf/hra-rdf-framework.xqm";
import module namespace hra-anno-framework = "http://hra.uni-heidelberg.de/ns/hra-anno-framework" at "../../frameworks/hra-annotations/hra-annotations.xqm";
import module namespace config = "http://exist-db.org/mods/config" at "../config.xqm";
import module namespace tamboti-security = "http://exist-db.org/mods/security" at "../../modules/search/security.xqm";

declare function apis:process() {
    let $method := request:get-method()
    
    let $path := substring-after(request:get-effective-uri(), "/api/")
    let $tokenized-path := tokenize($path, "/")
    
    let $scope := $tokenized-path[1]

    let $query-string := request:get-query-string()
    let $query-string := 
        if($query-string) then xmldb:decode($query-string)
        else ""
    let $parameters := subsequence($tokenized-path, 2)
    
    let $cors := 
        (
            response:set-header("Access-Control-Allow-Origin", "*"),
            response:set-header("Access-Control-Allow-Methods", "OPTIONS, GET, POST, PUT"),
            response:set-header("Access-Control-Allow-Headers", "authorization, _authToken, content-type, X-Custom-Header, user-agent, x-resource-id, X-target-collection")
        )
        
(:    let $cookieToken := request:get-header("_cookieToken"):)
(:    let $user :=:)
(:        let $user := tamboti-security:iiifauth-validate-cookie($cookieToken):)
(:        let $user-read := security:user-has-access($user, $collection-name, "r.x"):)
(::)
(:        let $info := util:log("INFO", "cookieToken: " || $cookieToken):)
(:        let $info := util:log("INFO", "user:" || tamboti-security:iiifauth-validate-cookie($cookieToken)):)

    return
        switch($method)
            case "GET"
            return apis:get($method, $scope, $parameters, $query-string)
            case "POST"
            return apis:post($method, $scope, $parameters)        
            case "PUT"
            return apis:put($method, $scope, $parameters)
            case "DELETE"
            return apis:delete($method, $scope, $parameters)
            case "HEAD"
            return apis:head($method, $scope, $parameters)
            case "OPTIONS"
            return apis:options($method, $scope, $parameters)
            default return ()    
};

declare function apis:get($method as xs:string, $scope as xs:string, $parameters as xs:string*, $query-string as xs:string?) {
    switch($scope)
        case "uuid"
        return apis:uuid()      
        case "resource"
        return apis:resource($parameters, $query-string)
        case "annotation"
        return apis:annotation($parameters)
        case "annotationsFor"
        return apis:get-annotations-for($parameters)
        case "targets"
        return apis:targets($parameters)
        case "annoCallbacks"
        return apis:getAnnoCallbacks($parameters)
        case "iiif"
        return apis:iiif($method, $scope, $parameters)
        case "search" return apis:search($parameters)  
        case "resources" return apis:resources()        
        default return () 
};

declare function apis:put($method as xs:string, $scope as xs:string, $parameters as xs:string*) {
	let $target-collection := xs:anyURI(request:get-header("X-target-collection"))
	let $resource-name := request:get-header("X-resource-id")
	
(:	let $resource-exist := tamboti-security:get-resource($resource-name):)
	
	let $target-collection :=
        if (starts-with($target-collection, "/db")) then
            substring-after($target-collection, "/db")
        else 
            $target-collection
    (: Only allow PUTting into /data/users/ :)
    return
        if(starts-with($target-collection, "/data/users") or starts-with($target-collection, "/data/commons")) then
        	let $content := request:get-data()
        	let $target-collection := xmldb:encode-uri(
                if (starts-with($target-collection, "/db")) then
                    substring-after($target-collection, "/db")
                else
                    $target-collection
        	)
  
            return
                let $result := tamboti-security:store-resource($target-collection, $resource-name, $content)
                    return
                        if($result instance of xs:boolean and $result = true()) then
                            (
                                (: creation was successful -  return 201 Created:)
                                response:set-status-code(201), 
                                <div>resource successfully created/updated</div>
                            )
                        else
                            (: Creation failed, return 403 Forbidden :)
                            (
                                response:set-status-code(500),
                                <div>resource creation/updating FAILED: {$result}</div>
                            )
        else
            (
                (: some collection outside of /data/users is addressed -> 403 Forbidden :)
                response:set-status-code(403),
                <div>You are not allowed to write to '{$target-collection}'</div>
            )
};

declare function apis:post($method as xs:string, $scope as xs:string, $parameters as xs:string*) {
    let $log := util:log("INFO", "scope: " || $scope)
    return
    switch($scope)
        case "editors"
        return apis:editors($parameters)
        case "annotation" return
            let $result := hra-rdf-framework:add-annotation($parameters[1], request:get-data(), false())
            return
                if($result) then
                    $result
                else 
                    response:set-status-code(500)
        case "annoConfig"
            return apis:annotationConfig($parameters)
        case "annotationsFor"
            return apis:post-annotations-for($parameters)
(:        case "annotationTest":)
(:            return apis:annotationTest($parameters):)
        default return ()
  
};


declare function apis:delete($method as xs:string, $scope as xs:string, $parameters as xs:string*) {
	(
		util:log("DEBUG", "DELETE X-resource-path = " || request:get-header("X-resource-path"))
		,
		<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		    <forward url="/rest/db{request:get-header("X-resource-path")}" absolute="yes"/>
		</dispatch>
	)
};

declare function apis:head($method as xs:string, $scope as xs:string, $parameters as xs:string*) {
    apis:iiif($method, $scope, $parameters)
};

declare function apis:options($method as xs:string, $scope as xs:string, $parameters as xs:string*) {
    <body/>
};

declare function apis:search($exist-prefix as xs:string) {
   <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
      <forward url="/modules/search/search.xql">
        <set-attribute name="exist:prefix" value="{$exist-prefix}"/>
      </forward>
   </dispatch>
};

declare function apis:search($parameters as xs:string*) {
    let $parameter := $parameters[1]
    
    return (
        response:set-header("Content-Type", "text/plain")
        ,
        switch ($parameter)
            case "simple"
            return apis:search-simple()
            case "advanced"
            return apis:search-advanced()        
            default return ()
    )
};

declare function apis:search-simple() {
   <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
      <forward url="/modules/search/simple-search.xql" />
   </dispatch>
};

declare function apis:search-advanced() {
   <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
      <forward url="/modules/search/advanced-search.xql" />
   </dispatch>
};

declare function apis:search-history() {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="../history.xq" />
    </dispatch> 
};

declare function apis:resources() {
    let $start := request:get-parameter("start", "")
    let $uuid-search-string := request:get-parameter("uuid", "")
    
    return (
        response:set-header("Content-Type", "text/html")
        ,
        if ($start != "")
        then session:get-attribute("tamboti:cached")[position() = ($start to $start)]
        else ()
    )
};

declare function apis:uuid() {
    text {"uuid-" || util:uuid()} 
};

declare function apis:editors($parameters as xs:string*) {
    let $editor-name := $parameters[1]
    let $query-string := local:generate-query-string-from-request-parameters()
    
    return
     switch($editor-name)
        case "hra-mods-editor"
        return
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <redirect url="{$config:web-path-to-mods-editor}?id={$parameters[2]}&amp;{$query-string}" />
            </dispatch> 
        case "tei-editor"
        return
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <redirect url="{$config:web-path-to-tei-editor}?session={$config:web-path-to-tei-hra-framework}/session.xml&amp;content={$config:web-path-to-tei-hra-framework}/get-data.xq?id={$parameters[2]}" />
            </dispatch>
        default return ()     
};




declare function apis:resource($parameters as xs:string*, $query-string as xs:string) {
    try {
        hra-rdf-framework:get-tamboti-resource($parameters[1], $query-string)
    } catch * {
        switch($err:code)
            case xs:QName("unauthorized") return
                let $header := response:set-status-code(401)
                return
                    <div>Unauthorized</div>
            
            case xs:QName("notFound") return
                let $header := response:set-status-code(404)
                return
                    <div>resource not found</div>

            default return
                let $header := response:set-status-code(500)
                return
                    <div>internal Server Error {$err:code} , {$err:description}, {$err:value}</div>

    }
};

declare function apis:annotation($parameters as xs:string*) {
    hra-rdf-framework:get-annotation($parameters[1])
};

declare function apis:get-annotations-for($parameters as xs:string*) {
    let $annotations := util:eval(xs:anyURI("../../frameworks/hra-annotations/annotations.xq"), false(), ((xs:QName("action"), "as-body-or-target"), (xs:QName("iri"), xmldb:decode-uri($parameters[1]))))
    return
        $annotations
};

declare function apis:post-annotations-for($parameters as xs:string*) {
    
    let $data := request:get-data()
(:    let $log := util:log("INFO", "***** API (POST) *******"):)
(:    let $log := util:log("INFO", $data):)
    let $annotations := util:eval(xs:anyURI("../../frameworks/hra-annotations/annotations.xq"), false(), ((xs:QName("action"), "save"), (xs:QName("htmldata"), $data)))
    return 
        $annotations
    (:    let $annotations := util:eval(xs:anyURI("../../frameworks/hra-annotations/annotations.xq"), false(), ((xs:QName("action"), "as-body-or-target"), (xs:QName("iri"), xmldb:decode-uri($parameters[1])))):)
(:    return:)
(:        $annotations:)
};


(:declare function apis:annotationTest($parameters as xs:string*) {:)
(:    let $data := root(request:get-data()):)
(:    let $anno-config-id := $data/div/@data-configid/string():)
(:    let $anno-type-idx := xs:integer($data/div/@data-annoidx/string()) + 1:)
(:(:    let $saveAnno := hra-rdf-framework:save-annotation($anno-config-id, $anno-type-idx, $data):):)
(:(:    let $log := util:log("INFO", $test):):)
(:    return:)
(:        <div>:)
(:            <data>{$data/div/@data-configid}</data>:)
(:            <test>{$anno-config-id}</test>:)
(:            <test>{$anno-type-idx}</test>:)
(:        </div>:)
(:};:)

declare function apis:targets($parameters) {
    let $anno-config-id := request:get-parameter("annoConfigId", ())
    let $log := util:log("INFO", "anno-cfg-id " || $anno-config-id)

    let $targets := hra-anno-framework:get-annotator-targets($parameters[1], $anno-config-id)
    return
        $targets
};

declare function apis:annotationConfig($parameters) {
    let $anno-config-id := request:get-parameter("annoConfigId", ())
    let $log := util:log("INFO", request:get-parameter-names())
    let $test := response:set-header("Content-Type", "text/html")
    return
        <div>{
        hra-anno-framework:get-annotator-config($anno-config-id)
        }</div>
};

declare function apis:getAnnoCallbacks($parameters) {
    <script type="text/javascript">
        {
            let $parameter-tokens := tokenize(substring-after(request:get-uri(), "/annoCallbacks/"), "/")
            let $config-id := $parameter-tokens[1]
            let $anno-type-id := $parameter-tokens[2]
            return
                if ($config-id and $anno-type-id) then
                    hra-anno-framework:get-callbacks($config-id, $anno-type-id)
                else
                    ()
                
            
        }
    </script>
};

declare function apis:iiif($method, $scope, $parameters) {
    switch ($method) 
        case "GET" return
            let $log := util:log("INFO", "GET request")
            let $log := util:log("INFO", request:get-cookie-names())
(:            let $log := util:log("INFO", request:get-parameter-names()):)
            let $forward-url := "/modules/display/iiif.xql"
            let $call := xmldb:decode(substring-after(request:get-uri(), "/api/iiif/"))
            let $call-tokens := tokenize($call, "/")
            return
                if(count($call-tokens) < 3 or $call-tokens[2] = "info.json") then
                    let $image-uuid := $call-tokens[1]
                    return
                        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                            <forward url="{$forward-url}">
                                <add-parameter name="image-uuid" value="{$image-uuid}"/>
                                <add-parameter name="action" value="iiif-info"/>
                                <add-parameter name="full-iiif-call" value="{$image-uuid || "/info.json"}"/>
                            </forward>
                        </dispatch>
                else if (count($call-tokens) = 5) then
                    let $image-uuid := $call-tokens[1]
                    return
                        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                            <forward url="{$forward-url}">
                                <add-parameter name="image-uuid" value="{$image-uuid}"/>
                                <add-parameter name="action" value="iiif-binary"/>
                                <add-parameter name="full-iiif-call" value="{$call}"/>
                            </forward>
                        </dispatch>
                else
                    let $header := response:set-status-code(500)
                    return
                        <div>invalid IIIF call</div>

        case "OPTIONS" return
            let $log := util:log("INFO", "OPTIONS request")
            let $head := response:set-status-code(200)
            let $head := response:set-header("Access-Control-Allow-Methods", "OPTIONS, HEAD, GET, POST")
            let $head := response:set-header("Access-Control-Allow-Headers", "Authorization")
            return
                <div/>
        case "HEAD" return
            (
                util:log("INFO", "HEAD request"),
                util:log("INFO", request:get-parameter-names())
            )
        default return 
            (
                util:log("INFO", "Irschenden annerer request")

            )
};

declare function local:generate-query-string-from-request-parameters() {
    let $query-string :=
        for $parameter-name in request:get-parameter-names()
        return $parameter-name || "=" || request:get-parameter($parameter-name, "")
    let $log := util:log("INFO", string-join($query-string, "&amp;"))
        
    return string-join($query-string, "&amp;")
};