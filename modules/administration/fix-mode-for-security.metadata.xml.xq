xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

for $file in collection($config:users-collection)[ends-with(document-uri(.), 'security.metadata.xml')]
let $file-path := document-uri($file)

return
    (
        sm:get-permissions($file-path),
        sm:chmod($file-path, $config:resource-mode),
        sm:get-permissions($file-path)
    )
