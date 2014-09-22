xquery version "3.0";

import module namespace security="http://exist-db.org/mods/security" at "/db/apps/tamboti/modules/search/security.xqm";

declare function local:recursively-inherit-permissions($collection-uri) {
    (
        security:copy-tamboti-collection-user-acl(xs:anyURI($collection-uri)) ,
        for $sub-collection in xmldb:get-child-collections($collection-uri)
            return
                (
                    security:copy-tamboti-collection-user-acl(xs:anyURI($collection-uri || "/" || $sub-collection)),
                    local:recursively-inherit-permissions($collection-uri || "/" || $sub-collection)
                )
    )
};

local:recursively-inherit-permissions("/resources/users/dulip.withanage@ad.uni-heidelberg.de/test")

