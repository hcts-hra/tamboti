xquery version "3.1";

declare namespace json="http://www.json.org";

import module namespace security="http://exist-db.org/mods/security" at "security.xqm";

declare variable $local:json-serialize-parameters :=
    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
        <output:method value="json"/>
        <output:media-type value="text/javascript"/>
    </output:serialization-parameters>;


declare function local:authenticate($user as xs:string, $password as xs:string?) as element() {
   try {
        if (security:login($user, $password))
        then <ok/>
        else (
            response:set-status-code(403),
            <span>Wrong username and/or wrong password.</span>
        )
   } catch * {
       (
           response:set-status-code(403)
           ,
           <span>{$err:description}</span>
       )
   }    
};

declare function local:get-all-subcollections($collection-uri as xs:anyURI) {
    let $child-collections := xmldb:get-child-collections($collection-uri)
    return
        (
            xs:anyURI($collection-uri)
            ,
            for $subcol in $child-collections
                let $subcol-uri := xs:anyURI($collection-uri || "/" || $subcol)
                return
                    local:get-all-subcollections($subcol-uri)
        )
};

declare function local:check-collection-remove-permissions($collection-uri as xs:anyURI) {
    let $col-and-subcols := local:get-all-subcollections($collection-uri)
    let $rwx := 
        for $col in $col-and-subcols
        
        return sm:has-access($col, "rwx")
        
    return
        (: if user does not have acces to one of the subcols: removing selected collection is not allowed :)
        if (false() = distinct-values($rwx))
        then false()
        else true()
};

(:~

: Describes a users relationship with a collection
:
: @param collection
:
: @return
:   <relationship user="{$user}" collection="{$collection}">
:       <home>{true or false indicating whether this collection is the users home collection}</home>
:       <owner>{true or false indicating whether the user owns this collection}</owner>
:       <read>{true or false indicating whether the user can read the collection}</read>
:       <write>{true or false indicating whether the user can write the collection}</write>
:       <execute>{true or false indicating whether the user can execute the collection}</execute>
:       <read-parent>{true or false indicating whether the user can read the collection}</read-parent>
:       <write-parent>{true or false indicating whether the user can write the collection}</write-parent>
:       <execute-parent>{true or false indicating whether the user can access the collection}</execute-parent>
:   </relationship>
:)
declare function local:collection-relationship($collection as xs:string) as element(relationship)
{
    let $collection := $collection
    let $parent := replace(replace($collection, "(.*)/.*", "$1"), '/db', '') 

    return
        <relationship user="{security:get-user-credential-from-session()[1]}" collection="{$collection}">
            <home json:literal="true">
            {
                replace($collection, '/db', '') eq security:get-home-collection-uri(security:get-user-credential-from-session()[1])
            }
            </home>
            <owner json:literal="true">
            {
                security:is-collection-owner(security:get-user-credential-from-session()[1], $collection)
            }
            </owner>
            <read json:literal="true">
            {
                security:can-read-collection($collection)
            }
            </read>
            <write json:literal="true">
            {
                security:can-write-collection($collection)
            }
            </write>
            <execute json:literal="true">
            {
                security:can-execute-collection($collection)
            }
            </execute>
            <remove json:literal="true">
            {
                security:can-write-collection($parent) and
                security:can-execute-collection($parent) and
                local:check-collection-remove-permissions($collection)
            }
            </remove>
            <copy json:literal="true">
            {
                security:can-read-collection($collection) and security:can-execute-collection($collection)
            }
            </copy>
            <move json:literal="true">
            {
                security:can-write-collection($parent) and
                security:can-execute-collection($parent) and
                security:can-write-collection($collection)
            }
            </move>
            <read-parent json:literal="true">
            {
                security:can-read-collection($parent)
            }
            </read-parent>
            <write-parent json:literal="true">
            {
                security:can-write-collection($parent)
            }
            </write-parent>
            <execute-parent json:literal="true">{security:can-execute-collection($parent)}
            </execute-parent>
        </relationship>
};

let $output-type := request:get-parameter("output", "")
let $action := request:get-parameter("action", ())

return
    if ($action)
    then
        (
            switch($action) 
                case "is-collection-owner" return
                    let $collection := xmldb:encode(request:get-parameter("collection",()))
                    return 
                        security:is-collection-owner(security:get-user-credential-from-session()[1], $collection)
                case "collection-relationship" return
                    let $collection := xmldb:encode(request:get-parameter("collection",()))
                    let $collection-relationship := local:collection-relationship($collection)
                    return
                        if($output-type = "json") then
                            let $header := response:set-header("Content-Type", "application/json")
                            return
                                serialize($collection-relationship, $local:json-serialize-parameters)
                        else
                            $collection-relationship
                case "logout" return
                    (
                        let $log := util:log("INFO", "CLEAR SESSION")
                        let $cookie := request:get-cookie-value("T-AUTH")
                        let $log := util:log("INFO", $cookie)
                        let $logoutResponse := request:get-parameter("callback", "loggedOut")
                        
                        let $clear-session :=
                            (
                                if($cookie) then
                                    (
                                        security:iiifauth-remove-cookie($cookie),
                                        response:set-cookie("T-AUTH", "", xs:duration("PT00S"),  (), request:get-server-name(), "/exist")
                                    )
                                else
                                    ()
                                ,
                                session:clear(),
                                session:invalidate()
                            )
                            let $header := response:set-header('Content-Type', 'text/javascript; charset=utf8')
                            return
                                (
                                    response:set-status-code(200),
                                    $logoutResponse || "('true')"
                                )
                    )
                            
                case "iiif-auth" return
                    (: try to login:)
                    let $loginResponse := request:get-parameter("callback", "loggedIn")
                    return
                        if(request:get-parameter("user", ()) and request:get-parameter("password", ())) then
                            if (security:login(request:get-parameter("user", ()), xmldb:decode(request:get-parameter("password", ())))) then
                                (: look for an existing cookie :)
                                let $log := util:log("INFO", "SET COOKIE")
                                let $cookie-value := security:iiifauth-set-cookie()
                                let $cookie := response:set-cookie("IIIFAUTH2", $cookie-value , xs:duration(("PT" || $security:cookie-lifetime div 1000) || "S"), (), "universalviewer.io", "/")
                                let $cookie := response:set-cookie("T-AUTH", $cookie-value , xs:duration(("PT" || $security:cookie-lifetime div 1000) || "S"), (), request:get-server-name(), "/exist")
                                let $header := response:set-header('Content-Type', 'text/javascript; charset=utf8')
    (:                                let $json := :)
    (:                                    serialize("true", $local:json-serialize-parameters):)
                                return
                                    (
                                        response:set-status-code(200),
                                        $loginResponse || "('" || $cookie-value || "')"
                                    )
                            else
                            (
                                response:set-status-code(403),
                                $loginResponse || "()"
                            )
                        else
                            let $header := response:set-header("Content-Type", "application/json")
    (:                        let $log := util:log("INFO", sm:id()):)
                            let $return := 
                                if(security:get-user-credential-from-session()[1] != "guest") then
                                    (
                                        response:set-status-code(200),
                                        <root json:literal="true">true</root>
                                    )
                                else
                                    ( 
                                        response:set-status-code(403),
                                        <root json:literal="true">false</root>
                                    )
                            return 
                                serialize($return, $local:json-serialize-parameters)
                default return
                    (
                        response:set-status-code(403),
                        <unknown action="{$action}"/>
                    )
        )
    else local:authenticate(request:get-parameter("user", ()), xmldb:decode(request:get-parameter("password", ())))