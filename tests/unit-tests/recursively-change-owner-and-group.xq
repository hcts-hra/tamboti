xquery version "3.0";

declare function local:setPerm($path, $user-id, $group-id, $collection-mode, $resource-mode) {
        (: Change permissions for resources in parent collection :)
        (
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

let $path := "/resources/users/freizo-editor" 

let $user-id := "freizo-editor" 
let $group-id := "biblio.users" 
let $collection-mode := "rwxr-xr-x"
let $resource-mode := "rw-------"

return 
    local:setPerm($path, $user-id, $group-id, $collection-mode, $resource-mode)