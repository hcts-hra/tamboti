xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

declare function local:set-group($path) {
    (
    let $group-id := $config:biblio-users-group 
    return
        (
        for $collection in xmldb:get-child-collections($path)
        return
            (
                sm:chgrp(xs:anyURI($path || "/" || $collection), $group-id),
                local:set-group($path || "/" ||$collection)
            )
        ,
        for $resource in xmldb:get-child-resources($path)
        return sm:chgrp(xs:anyURI($path || "/" || $resource), $group-id)
        )
    )
};

let $path := $config:users-collection 
return
    for $user-collection-name in xmldb:get-child-collections($path)
    return local:set-group($path || "/" || $user-collection-name)
