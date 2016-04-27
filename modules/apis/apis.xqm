xquery version "3.0";

module namespace apis = "http://hra.uni-heidelberg.de/ns/tamboti/apis/";
import module namespace hra-rdf-framework = "http://hra.uni-heidelberg.de/ns/hra-rdf-framework" at "../../frameworks/hra-rdf/hra-rdf-framework.xqm";
import module namespace config = "http://exist-db.org/mods/config" at "../config.xqm";
import module namespace tamboti-security = "http://exist-db.org/mods/security" at "../../modules/search/security.xqm";

declare function apis:process() {
(:    let $parsedIRI := hra-rdf-framework:parse-IRI(request:get-effective-uri(), "xml"):)
(:    let $log := util:log("INFO", $parsedIRI/*):)
    
    let $method := request:get-method()
    
    let $path := substring-after(request:get-effective-uri(), "/api/")
    let $tokenized-path := tokenize($path, "/")
    
    let $scope := $tokenized-path[1]

    let $query-string := request:get-query-string()
    let $query-string := 
        if($query-string) then xmldb:decode($query-string)
        else ""
    let $parameters := subsequence($tokenized-path, 2)
    
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
        default return () 
};

declare function apis:put($method as xs:string, $scope as xs:string, $parameters as xs:string*) {
    let $target-collection := xs:anyURI(request:get-header("X-target-collection"))
    let $resource-name := request:get-header("X-resource-name")
    let $content := request:get-data()
    let $target-collection := xmldb:encode-uri(
        if (starts-with($target-collection, "/db")) then
            substring-after($target-collection, "/db")
        else
            $target-collection
    )
       
    return
        if (not(xmldb:collection-available($target-collection)))
        then
            (
                response:set-status-code(404)
                ,
                <error>The target collection '{$target-collection}' does not exist!</error>
            )
        else
            <div>
                {
                    let $result := tamboti-security:store-resource($target-collection, $resource-name, $content)
                    return
                        if($result = true()) then
                            "success"
                        else
                            (
                                response:set-status-code(500),
                                $result
                            )
    
                }
            </div>
};

declare function apis:post($method as xs:string, $scope as xs:string, $parameters as xs:string*) {
    switch($scope)
        case "editors"
        return apis:editors($parameters)
        case "annotation" return
            let $result := hra-rdf-framework:add-annotation($parameters[1], request:get-data())
            return
                if($result) then
                    $result
                else 
                    response:set-status-code(500)
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

declare function apis:search($exist-prefix as xs:string) {
   <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
      <forward url="/modules/search/search.xq">
        <set-attribute name="exist:prefix" value="{$exist-prefix}"/>
      </forward>
   </dispatch>
};

declare function apis:search-history() {
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="../history.xq" />
    </dispatch> 
};

declare function apis:uuid() {
    text {"uuid-" || util:uuid()} 
};

declare function apis:editors($parameters as xs:string*) {
    let $editor-name := $parameters[1]
    let $log := util:log("INFO", "request:get-parameter-names()")
    let $log := util:log("INFO", request:get-parameter-names())
    let $log := util:log("INFO", "get-data")
    let $log := util:log("INFO", request:get-parameter("type", ""))
    let $query-string := local:generate-query-string-from-request-parameters()
    
    return
     switch($editor-name)
        case "hra-mods-editor"
        return
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <redirect url="{$config:web-path-to-mods-editor}?id={$parameters[2]}&amp;{$query-string}" />
            </dispatch>            
        default return ()     
};

declare function apis:resource($parameters as xs:string*, $query-string as xs:string) {
    hra-rdf-framework:get-tamboti-resource($parameters[1], $query-string)
};

declare function apis:annotation($parameters as xs:string*) {
    hra-rdf-framework:get-annotation($parameters[1])
};

declare function local:generate-query-string-from-request-parameters() {
    let $query-string :=
        for $parameter-name in request:get-parameter-names()
        return $parameter-name || "=" || request:get-parameter($parameter-name, "")
    let $log := util:log("INFO", string-join($query-string, "&amp;"))
        
    return string-join($query-string, "&amp;")
};
