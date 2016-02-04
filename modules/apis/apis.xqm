xquery version "3.0";

module namespace apis = "http://hra.uni-heidelberg.de/ns/tamboti/apis/";

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
