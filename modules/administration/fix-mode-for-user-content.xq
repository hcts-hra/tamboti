xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace reports = "http://hra.uni-heidelberg.de/ns/tamboti/reports" at "../../reports/reports.xqm";

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

for $collection-path in $reports:collections
return
    for $collection-name in xmldb:get-child-collections(xs:anyURI($collection-path))
    return local:set-mode($collection-path || "/" || $collection-name)
