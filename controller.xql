xquery version "3.1";

import module namespace session ="http://exist-db.org/xquery/session";

import module namespace config = "http://exist-db.org/mods/config" at "modules/config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "modules/search/security.xqm";
import module namespace theme = "http://exist-db.org/xquery/biblio/theme" at "modules/theme.xqm";
import module namespace apis = "http://hra.uni-heidelberg.de/ns/tamboti/apis/" at "modules/apis/apis.xqm";

declare namespace exist = "http://exist.sourceforge.net/NS/exist";

declare variable $exist:controller external;
declare variable $exist:root external;
declare variable $exist:prefix external;
declare variable $exist:path external;
declare variable $exist:resource external;

declare variable $local:item-uri-regexp := "/item/([a-z0-9-_]*)";

declare function local:get-item($controller as xs:string, $root as xs:string, $prefix as xs:string?, $path as xs:string, $resource as xs:string?, $username as xs:string?, $password as xs:string?) as element(exist:dispatch) {
    
    let $item-id := fn:replace($path, $local:item-uri-regexp, "$1") return
    
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">        
            <forward url="{theme:resolve-uri($prefix, $root, 'pages/index.html')}">
                { local:set-user($username, $password) }
            </forward>
            <view>
                <forward url="../modules/search/search.xql">
                    <set-attribute name="xquery.report-errors" value="yes"/>
                    
                    <set-attribute name="exist:root" value="{$root}"/>
                    <set-attribute name="exist:path" value="{$path}"/>
                    <set-attribute name="exist:prefix" value="{$prefix}"/>
                    
                    <add-parameter name="id" value="{$item-id}"/>
                </forward>
            </view>
        </dispatch>
        (:
        <add-parameter name="filter" value="ID"/>
        <add-parameter name="value" value="{$item-id}"/>
        :)
};

declare function local:set-user($username as xs:string?, $password as xs:string?) {
    session:create(),
    let $session-user-credential := security:get-user-credential-from-session()
    return
        if ($username) then (
            security:store-user-credential-in-session($username, $password),
            <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.user" value="{$username}"/>,
            <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.password" value="{$password}"/>
        ) else if ($session-user-credential != '') then (
            <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.user" value="{$session-user-credential[1]}"/>,
            <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.password" value="{$session-user-credential[2]}"/>
        ) else (
            <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.user" value="{$security:GUEST_CREDENTIALS[1]}"/>,
            <set-attribute xmlns="http://exist.sourceforge.net/NS/exist" name="xquery.password" value="{$security:GUEST_CREDENTIALS[2]}"/>
        )
};

let 
    $username :=
        if(request:get-parameter("username",()))then
            config:rewrite-username(request:get-parameter("username",()))
        else()
    ,
    $password := request:get-parameter("password",())
(: let $log := util:log("INFO", "Controller-Cookies: " || string-join(request:get-cookie-names(), ":")) :)
return
    
    if ($exist:path eq '') then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="{concat(request:get-uri(), '/')}"/>
        </dispatch>
    else if (contains($exist:path, "/api/")) then
        switch (request:get-header("Accept"))
            case "application/json" return
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward url="/modules/apis/json-apis.xq"/>
                </dispatch>
            default return
                apis:process()
    else if ($exist:path = ('/bib')) then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="modules/search/bib.html"/>
        </dispatch>
     else if ($exist:path = ('/database','/databases')) then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="modules/search/databases.html"/>
        </dispatch>
        
     else if ($exist:path eq '/') then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="modules/search/index.html"/>
        </dispatch>

     else if ($exist:resource eq 'retrieve') then

        (:  Retrieve an item from the query results stored in the HTTP session. The
           format of the URL will be /sandbox/results/X, where X is the number of the
           item in the result set :)

       <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
           { local:set-user($username, $password) }
          <forward url="../modules/session.xql">
          </forward>
       </dispatch>

    else if (contains($exist:path, "/$shared/")) then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="/apps/shared-resources/{substring-after($exist:path, '/$shared/')}" absolute="yes"/>
        </dispatch>
            
    else if (starts-with($exist:path, "/item/resources")) then
        let $real-resources-path := fn:concat($exist:controller, "/", substring-after($exist:path, "/item/")) return
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$real-resources-path}">
                </forward>
            </dispatch>
    
    else if (starts-with($exist:path, "/item/images")) then
        let $real-resources-path := fn:concat("/", substring-after($exist:path, "/item/images"))
        (:let $log := util:log("ERROR", ("IMAGE: ", $real-resources-path)):)
        return
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$real-resources-path}">
                </forward>
            </dispatch>
            
    else if(fn:starts-with($exist:path, "/item/")) then
        local:get-item($exist:controller, $exist:root, $exist:prefix || "/" || $config:app-id, $exist:path, $exist:resource, $username, $password)

    (: rewrite the url if image.xql (old image call) is adressed :)
    else if(contains($exist:path, "/modules/display/image.xql") ) then
        let $schema := request:get-parameter("schema", "local")
        let $width := request:get-parameter("width", () )
        let $height := request:get-parameter("height", () )
        let $call := 
            if($schema = "IIIF") then
                substring-after(request:get-parameter("call", ""), "/")
            (: no standardized protocol means 'historical' local call :)
            else if (not($width = "" and $height = "")) then
                let $size := 
                    if($width or $height) then
                        "!" || $width || "," || $height
                    else
                        "full"
                    return 
                        request:get-parameter("uuid", "") || "/full/" || $size || "/0/default.jpg"
            (: its a genuine IIIF-Call:)
            else 
                substring-after($exist:path, "/iiif/")
        
        let $call-tokens := tokenize($call, "/")
        let $image-uuid := $call-tokens[1]
        let $redirect-uri := "/exist" || $exist:prefix || "/iiif/" || $call
        return
(:            <d>:)
                <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                    <redirect url="{$redirect-uri}"/>
                </dispatch>
(:            </d>:)

    else if(starts-with($exist:path, "/iiif/")) then
        let $forward-url := "/modules/display/iiif.xql"
        let $call := xmldb:decode(substring-after($exist:path, "/iiif/"))
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
                let $qualityformat := tokenize($call-tokens[5], "\.")
                return
                    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward url="{$forward-url}">
                            <add-parameter name="image-uuid" value="{$image-uuid}"/>
                            <add-parameter name="action" value="iiif-binary"/>
                            <add-parameter name="region" value="{$call-tokens[2]}"/>
                            <add-parameter name="size" value="{$call-tokens[3]}"/>
                            <add-parameter name="rotation" value="{$call-tokens[4]}"/>
                            <add-parameter name="quality" value="{$qualityformat[1]}"/>
                            <add-parameter name="format" value="{$qualityformat[2]}"/>
                            <add-parameter name="full-iiif-call" value="{$call}"/>
                        </forward>
                    </dispatch>
            else
                let $header := response:set-status-code(500)
                return
                    <div>invalid IIIF call</div>

    else
        (: everything else is passed through :)
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <cache-control cache="yes"/>
        </dispatch>