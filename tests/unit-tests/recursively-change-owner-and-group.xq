xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

declare function local:setPerm($path, $user-id, $group-id, $collection-mode, $resource-mode) {

        (
            sm:chown(xs:anyURI($path), $user-id),
            sm:chgrp(xs:anyURI($path), $group-id),
            sm:chmod(xs:anyURI($path), $collection-mode),
            (: recursive call for subcollections:)

            (: Change permissions for resources in parent collection :)
            for $res in xmldb:get-child-resources($path)
                return
                    (
                        sm:chown(xs:anyURI($path || "/" || $res), $user-id),
                        sm:chgrp(xs:anyURI($path || "/" || $res), $group-id),
                        sm:chmod(xs:anyURI($path || "/" || $res), $resource-mode)
                    )
            ,
            (: Change Permission for collections in parent collections           :)
            for $col in xmldb:get-child-collections($path)
                return
                    (
                        sm:chown(xs:anyURI($path || "/" || $col), $user-id),
                        sm:chgrp(xs:anyURI($path || "/" || $col), $group-id),
                        sm:chmod(xs:anyURI($path || "/" || $col), $collection-mode),
                        (: recursive call for subcollections:)
                        local:setPerm($path || "/" ||$col, $user-id, $group-id, $collection-mode, $resource-mode)
                    )
        )
};

let $path := $config:mods-commons || "/Cluster%20Publications" 

let $user-id := "editor" 
let $group-id := "biblio.users" 

return 
    local:setPerm($path, $user-id, $group-id, $config:collection-mode, $config:resource-mode)
