xquery version "3.0";

import module namespace security="http://exist-db.org/mods/security" at "security.xqm";
import module namespace sharing="http://exist-db.org/mods/sharing" at "sharing.xqm";
import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";

declare namespace request = "http://exist-db.org/xquery/request";
declare namespace response = "http://exist-db.org/xquery/response";

declare function local:authenticate($user as xs:string, $password as xs:string?) as element()
{
    if (security:login($user, $password)) then
        <ok/>
    else (
        response:set-status-code(403),
        <span>Wrong username and/or wrong password.</span>
    )
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
            <home>
            {
                replace($collection, '/db', '') eq security:get-home-collection-uri(security:get-user-credential-from-session()[1])
            }
            </home>
            <owner>
            {
                security:is-collection-owner(security:get-user-credential-from-session()[1], $collection)
            }
            </owner>
            <read>
            {
                security:can-read-collection($collection)
            }
            </read>
            <write>
            {
                security:can-write-collection($collection)
            }
            </write>
            <execute>
            {
                security:can-execute-collection($collection)
            }
            </execute>
            <read-parent>
            {
                security:can-read-collection($parent)
            }
            </read-parent>
            <write-parent>
            {
                security:can-write-collection($parent)
            }
            </write-parent>
            <execute-parent>
            {
                security:can-execute-collection($parent)
            }
            </execute-parent>
        </relationship>
};

if (request:get-parameter("action", ())) 
then
(
    let $action := request:get-parameter("action", ()) 
    return
        if ($action eq "is-collection-owner") then
            let $collection := xmldb:encode(request:get-parameter("collection",()))
            return 
                security:is-collection-owner(security:get-user-credential-from-session()[1], $collection)
        else if ($action eq "collection-relationship") then
            let $collection := xmldb:encode(request:get-parameter("collection",()))
            return 
                local:collection-relationship($collection)
        else
            (
                response:set-status-code(403),
                <unknown action="{$action}"/>
            )
)
else
    local:authenticate(request:get-parameter("user", ()), xmldb:decode(request:get-parameter("password", ())))