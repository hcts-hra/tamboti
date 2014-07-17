xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

declare function local:set-mode($path) {
    (
        sm:chmod($path, $config:collection-mode)
        ,
        for $collection in xmldb:get-child-collections($path)
        let $collection-path := xs:anyURI($path || "/" || $collection)
        return
            (
                sm:chmod($collection-path, $config:collection-mode),
                local:set-mode($collection-path)
            )
        ,
        for $resource in xmldb:get-child-resources($path)
        return sm:chmod(xs:anyURI($path || "/" || $resource), $config:resource-mode)
    )
};

for $user-collection-name in xmldb:get-child-collections($config:users-collection)
return local:set-mode($config:users-collection || "/" || $user-collection-name)
