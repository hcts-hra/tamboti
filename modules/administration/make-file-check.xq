xquery version "3.0";

import module namespace security="http://exist-db.org/mods/security" at "../modules/search/security.xqm";
import module namespace functx = "http://www.functx.com";
import module namespace config = "http://exist-db.org/mods/config" at "../modules/config.xqm";

declare namespace mods = "http://www.loc.gov/mods/v3";

declare variable $username as xs:string := "admin";
declare variable $password as xs:string := "test";

let $date := substring-before(util:system-date() cast as xs:string, '+') 
let $out-collection := '/db/apps/tamboti/admin/file-checks'
let $login := xmldb:login($out-collection, $username, $password)

let $records  :=
<records>
    {
for $record in collection($config:mods-root)//mods:mods

let $base-uri := base-uri($record)
let $location := functx:substring-before-last-match($base-uri, '/')
let $name := functx:substring-after-last($base-uri, '/')
let $last-modified := xmldb:last-modified($location, $name)
let $created := xmldb:created($location, $name)
let $size := xmldb:size($location, $name)
let $owner := security:get-owner(concat($location, "/", $name))
let $group := security:get-group(concat($location, "/", $name))
return
    
<record>
    <name>{$name}</name>
    <location>{$location}</location>
    <created>{$created}</created>
    <last-modified>{$last-modified}</last-modified>
    <size>{$size}</size>
    <owner>{$owner}</owner>
    <group>{$group}</group>
    </record>
} </records>

return xmldb:store($out-collection, concat($date, '.xml'), $records)