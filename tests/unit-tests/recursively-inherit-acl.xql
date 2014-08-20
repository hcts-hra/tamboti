xquery version "3.0";

import module namespace inherit-acl="http://hra.uni-heidelberg.de/ns/tamboti/unit-tests/inherit-acl.xq" at "/db/apps/tamboti/tests/unit-tests/inherit-acl.xqm";

declare function local:recursively-inherit-permissions($collection-uri) {
    (
    inherit-acl:inherit-tamboti-collection-user-acl(xs:anyURI($collection-uri)),
    for $sub-collection in xmldb:get-child-collections($collection-uri)
    return
        (
            inherit-acl:inherit-tamboti-collection-user-acl(xs:anyURI($collection-uri || "/" || $sub-collection)),
            local:recursively-inherit-permissions($collection-uri || "/" || $sub-collection)
        )
    )
};

local:recursively-inherit-permissions("/resources/users/dulip.withanage@ad.uni-heidelberg.de/test")

