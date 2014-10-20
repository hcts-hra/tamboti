xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace reports = "http://hra.uni-heidelberg.de/ns/tamboti/reports" at "../../reports/reports.xqm";

declare function local:set-group($path) {
    (
    let $group-id := $config:biblio-users-group 
    return
        (
            sm:chgrp(xs:anyURI($path), $group-id)
            ,
            for $collection in xmldb:get-child-collections($path)
            return
                (
                    sm:chgrp(xs:anyURI($path || "/" || $collection), $group-id)
                    ,
                    local:set-group($path || "/" ||$collection)
                )
            ,
            for $resource in xmldb:get-child-resources($path)
            return sm:chgrp(xs:anyURI($path || "/" || $resource), $group-id)
            )
    )
};

for $collection-path in $reports:collections
return
    for $collection-name in xmldb:get-child-collections($collection-path)
    return local:set-group($collection-path || "/" || $collection-name)
