xquery version "3.1";

(:~ Retrieve the XML source of a MODS or VRA record :)

import module namespace security="http://exist-db.org/mods/security" at "security.xqm";

import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";
import module namespace clean="http://exist-db.org/xquery/mods/cleanup" at "cleanup.xql";

declare option exist:serialize "method=xml media-type=application/xml indent=yes";

let $id := request:get-parameter("id", ())
let $clean := request:get-parameter("clean", "no")
(: if (by error) several records should have the same id, take the first record. :)
let $data := security:get-resource($id)

return
    if (empty($data)) 
        then <error>No record found for id: {$id} by {xmldb:get-current-user()}.</error>
    else
        if ($clean eq "yes") 
        then clean:cleanup-for-code-view($data)
        else
           if ($clean eq "soft") 
           (:Leaves empty @transliteration.:)
           then clean:cleanup($data)
           else $data