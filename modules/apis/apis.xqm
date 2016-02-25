xquery version "3.0";

module namespace apis = "http://hra.uni-heidelberg.de/ns/tamboti/apis/";

import module namespace config = "http://exist-db.org/mods/config" at "../config.xqm";

declare function apis:process() {
    let $method := request:get-method()
    
    let $path := substring-after(request:get-effective-uri(), "/api/")
    let $tokenized-path := tokenize($path, "/")
    
    let $scope := $tokenized-path[1]
    let $parameters := subsequence($tokenized-path, 2)
    
    return
     switch($method)
        case "GET"
        return apis:get($method, $scope, $parameters)     
        case "PUT"
        return apis:put($method, $scope, $parameters)
        case "DELETE"
        return apis:delete($method, $scope, $parameters)
        default return ()    
};

declare function apis:get($method as xs:string, $scope as xs:string, $parameters as xs:string*) {
    switch($scope)
        case "editors"
        return apis:editors($parameters)
        case "uuid"
        return apis:uuid()        
        default return () 
};

declare function apis:put($method as xs:string, $scope as xs:string, $parameters as xs:string*) {
	let $target-collection := xs:anyURI(request:get-header("X-target-collection"))
	
	return
	    if (not(xmldb:collection-available($target-collection)))
	    then
	        (
	            response:set-status-code(404)
	            ,
	            <error>The target collection '{$target-collection}' does not exist!</error>
	        )
	    else
	        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
	            <forward url="/rest/db{$target-collection}/{request:get-header("X-resource-name")}" absolute="yes"/>
	        </dispatch>
};

declare function apis:delete($method as xs:string, $scope as xs:string, $parameters as xs:string*) {
	(
		util:log("INFO", "DELETE X-resource-path = " || request:get-header("X-resource-path"))
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

declare function apis:editors($parameters as xs:string*) {
    let $editor-name := $parameters[1]
    
    return
     switch($editor-name)
        case "hra-mods-editor"
        return
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <redirect url="{$config:mods-editor-path}?id={$parameters[2]}&amp;collection={request:get-header('X-target-collection')}&amp;type={request:get-header('X-document-type')}" />
            </dispatch>            
        default return ()     
};

declare function apis:uuid() {
    text {"uuid-" || util:uuid()} 
};
