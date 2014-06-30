xquery version "3.0";

declare function local:set-group($path) {
    (
    let $group-id := "biblio.users" 
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

let $path := "/resources/users" 
return
    for $user-collection-name in xmldb:get-child-collections($path)
    return local:set-group($path || "/" || $user-collection-name)
