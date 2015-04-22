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
                    installation:set-resource-properties(xs:anyURI($newColl), $permissions)
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

declare function installation:set-resource-properties($resource-path as xs:anyURI, $permissions as xs:string) {
    (
        security:set-resource-permissions($resource-path, $config:biblio-admin-user, $config:biblio-users-group, $permissions)        
    )
};

declare function installation:set-resources-properties($collection-path as xs:anyURI, $permissions as xs:string) {
    for $resource-name in xmldb:get-child-resources($collection-path)
    return installation:set-resource-properties(xs:anyURI(concat($collection-path, '/', $resource-name)), $permissions)
};

declare function installation:set-child-resources-properties($collection-path as xs:anyURI, $permissions as xs:string) {
    for $resource-name in xmldb:get-child-resources($collection-path)
    return installation:set-resource-properties(xs:anyURI(concat($collection-path, '/', $resource-name)), $permissions)
};
