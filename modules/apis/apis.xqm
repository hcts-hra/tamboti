xquery version "3.0";

module namespace apis = "http://hra.uni-heidelberg.de/ns/tamboti/apis/";

import module namespace config = "http://exist-db.org/mods/config" at "../config.xqm";

declare function apis:process() {
    let $method := request:get-method()
    
    return
     switch($method)
        case "GET"
        return apis:get()     
        case "PUT"
        return apis:put()
        case "DELETE"
        return apis:delete()
        default return ()    
};

declare function apis:get() {
    let $path := substring-after(request:get-effective-uri(), "/api/")
	let $scope := replace($path, "/.*$", "")
	let $parameters := replace(substring-after($path, $scope), "^/", "")
	
    return
     switch($scope)
        case "editors"
        return apis:editors($parameters)     
        default return () 
};

declare function apis:put() {
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

declare function apis:delete() {
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

declare function apis:editors($parameters as xs:string) {
    let $editor-name := $parameters
    let $log := util:log("INFO", "$config:mods-editor-path = " || $config:mods-editor-path)
    
    return
     switch($editor-name)
        case "hra-mods-editor"
        return
           <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
              <forward url="../../../..{$config:mods-editor-index-db-path}" />
           </dispatch>            
        default return ()     
};
