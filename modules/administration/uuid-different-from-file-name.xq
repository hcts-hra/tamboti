xquery version "3.0";
declare namespace mods = "http://www.loc.gov/mods/v3";
for $record in //mods:mods
let $ID := $record/@ID
let $location := base-uri($record)
let $file-name := concat('uuid-', substring-after($location, 'uuid-'))
return
if ($ID/string() and $file-name ne concat($ID, '.xml'))
then concat($location, ' ', $ID)
else ()