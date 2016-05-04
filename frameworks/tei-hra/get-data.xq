xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

let $id := request:get-parameter('id', '')

return system:as-user($config:dba-credentials[1], $config:dba-credentials[2], root(collection($config:content-root)//*[@xml:id = $id]))
