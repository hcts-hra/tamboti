xquery version "3.0";
declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace functx = "http://www.functx.com";

declare function functx:substring-before-last-match 
  ( $arg as xs:string? ,
    $regex as xs:string )  as xs:string? {
       
   replace($arg,concat('^(.*)',$regex,'.*'),'$1')
 } ;
 
declare function functx:substring-after-last 
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string {
       
   replace ($arg,concat('^.*',functx:escape-for-regex($delim)),'')
 } ;
 
declare function functx:escape-for-regex 
  ( $arg as xs:string? )  as xs:string {
       
   replace($arg,
           '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
 } ;

declare variable $username as xs:string := "admin";
declare variable $password as xs:string := "test";

let $date := substring-before(util:system-date() cast as xs:string, '+') 
let $out-collection := '/db/apps/tamboti/admin/file-checks'
let $login := xmldb:login($out-collection, $username, $password)

let $records  :=
<records>
    {
for $record in collection('/db/resources/')//mods:mods

let $base-uri := base-uri($record)
let $location := functx:substring-before-last-match($base-uri, '/')
let $name := functx:substring-after-last($base-uri, '/')
let $last-modified := xmldb:last-modified($location, $name)
let $created := xmldb:created($location, $name)
let $size := xmldb:size($location, $name)
let $owner := xmldb:get-owner($location, $name)
let $group := xmldb:get-group($location, $name)
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