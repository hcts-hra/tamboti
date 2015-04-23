xquery version "3.0";

module namespace installation = "http://hra.uni-heidelberg.de/ns/tamboti/installation/";

import module namespace config = "http://exist-db.org/mods/config" at "xmldb:exist:///db/apps/tamboti/modules/config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "xmldb:exist:///db/apps/tamboti/modules/search/security.xqm";

(:~ Functions needed for pre-install.xq of tamboti and tamboti-samples apps :)
declare function installation:mkcol-recursive($collection, $components, $permissions as xs:string) {
    if (exists($components))
    then
        let $newColl := concat($collection, "/", $components[1])
        return (
            if (not(xmldb:collection-available($newColl)))
            then
                (
                    xmldb:create-collection($collection, $components[1])
                    ,
                    security:set-resource-permissions(xs:anyURI($newColl), $config:biblio-admin-user, $config:biblio-users-group, $permissions)
                )
            else ()
            ,
            installation:mkcol-recursive($newColl, subsequence($components, 2), $permissions)
        )
    else ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function installation:mkcol($collection, $path, $permissions as xs:string) {
    installation:mkcol-recursive($collection, tokenize($path, "/"), $permissions)
};

declare function installation:set-public-collection-permissions-recursively($collection-path as xs:anyURI) {
    (
        security:set-resource-permissions($collection-path, $config:biblio-admin-user, $config:biblio-users-group, $config:public-collection-mode)
        ,
        for $subcollection-name in xmldb:get-child-collections($collection-path)
        return installation:set-public-collection-permissions-recursively(xs:anyURI($collection-path || "/" || $subcollection-name))
        ,
        for $resource-name in xmldb:get-child-resources($collection-path)
        return security:set-resource-permissions(xs:anyURI(concat($collection-path, '/', $resource-name)), $config:biblio-admin-user, $config:biblio-users-group, $config:public-resource-mode)
    )
};
