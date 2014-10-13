xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

let $vma-collection := $config:users-collection || "/vma-editor/VMA-Collection"
let $vma-collection-ace := sm:get-permissions(xs:anyURI($vma-collection))
let $shared-to-users := $vma-collection-ace//sm:ace/@who
let $mode := "rwx"

return
    for $subcollection in xmldb:get-child-collections($vma-collection)
    return 
        for $shared-to-user in $shared-to-users
        let $subcollection-path := $vma-collection || "/" || $subcollection
        let $set-ace := sm:add-user-ace($subcollection-path, $shared-to-user, true(), $mode)
        return sm:get-permissions(xs:anyURI($subcollection-path))


(:sm:add-user-ace($path as xs:anyURI, $user-name as xs:string, $allowed as xs:boolean, $mode as xs:string) as empty():)
