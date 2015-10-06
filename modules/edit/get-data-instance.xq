xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../config.xqm";
declare namespace mods = "http://www.loc.gov/mods/v3";

let $id := request:get-parameter('id', '')

let $data-instance :=
    if ($id)
    then collection($config:content-root)//mods:mods[@ID = $id]
    else doc(concat($config:edit-app-root, '/instances/', request:get-parameter('data-template-name', ''), '.xml'))


return $data-instance
