xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

declare function local:delete-acl($collection-path as xs:string) {
    (
        sm:clear-acl(xs:anyURI($collection-path)),
        
        for $resource-name in xmldb:get-child-resources($collection-path)
        return sm: clear-acl(xs:anyURI($collection-path || "/" || $resource-name)),
        
        for $collection-name in xmldb:get-child-collections($collection-path)
        return local:delete-acl($collection-path || "/" || $collection-name)
    )
};

let $vma-collection-path := xs:anyURI($config:users-collection || "/vma-editor/VMA-Collection")

return
    for $vma-subcollection-name in xmldb:get-child-collections($vma-collection-path)
    let $vma-subcollection-path := $vma-collection-path || "/" || $vma-subcollection-name
    return
        (
            $vma-subcollection-path,
            local:delete-acl($vma-subcollection-path),
            sm:get-permissions($vma-subcollection-path)
        )
