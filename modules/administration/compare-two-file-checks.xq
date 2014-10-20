xquery version "3.0";

import module namespace functx = "http://www.functx.com";
import module namespace config = "http://exist-db.org/mods/config" at "../modules/config.xqm";

declare variable $username as xs:string := "admin";
declare variable $password as xs:string := "test";

let $date := substring-before(util:system-date() cast as xs:string, '+') 

let $deletions := $config:mods-root || '/temp/deletions.xml'
let $file-checks := '/db/apps/tamboti/admin/file-checks/'
let $login := xmldb:login($file-checks, $username, $password)

let $old := '2013-05-27.xml'
let $new := '2013-05-28.xml'

let $old-doc := doc($file-checks || $old)

let $old-names := $old-doc//name

let $new-names := doc($file-checks || $new)//name
let $deletions-names := doc($deletions)//name

let $missing := functx:value-except($old-names, $new-names)
let $missing := functx:value-except($missing, $deletions-names)

let $missing :=
<records>{
for $name in $missing 
return $old-doc//record[name eq $name]
}</records>

return xmldb:store($file-checks, concat('missing.', $date, '.xml'), $missing)