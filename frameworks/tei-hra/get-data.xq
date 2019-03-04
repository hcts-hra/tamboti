xquery version "3.1";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

let $id := request:get-parameter('id', '')

return root(collection($config:content-root)//*[@xml:id = $id])
