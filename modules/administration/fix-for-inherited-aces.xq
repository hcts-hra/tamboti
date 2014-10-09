xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

declare function local:copy-user-ace($source, $target) {
    (: first remove ACL on target :)
    sm:clear-acl(xs:anyURI($target)),
    (: add each ACE from collection to target:)
    for $ace in sm:get-permissions($source)//sm:ace
        let $username := $ace/@who
        let $allowed := if ($ace/@access_type = "ALLOWED") then 
            true()
        else 
            false()
        let $mode := $ace/@mode
        return 
            sm:add-user-ace(xs:anyURI($target), $username, $allowed, $mode)

    
};

declare function local:inherit-collection-user-acl-to-resources($collection as xs:anyURI) {
    for $resource-name in xmldb:get-child-resources($collection)
        return
            (
                (: first remove ACL on resource :)
                sm:clear-acl(xs:anyURI($collection || "/" || $resource-name)),
                (: add each ACE from collection to resource:)
                for $ace in sm:get-permissions($collection)//sm:ace
                    let $username := $ace/@who
                    let $allowed := if ($ace/@access_type = "ALLOWED") then 
                        true()
                    else 
                        false()
                    let $mode := $ace/@mode
                    return 
                        sm:add-user-ace(xs:anyURI($collection || "/" || $resource-name), $username, $allowed, $mode)
            )
};

declare function local:inherit-tamboti-collection-user-acl($collection as xs:anyURI) {
        
    (: update ACL for resources in parent collection  :)
    local:inherit-collection-user-acl-to-resources(xs:anyURI($collection)),
    
    if (xmldb:collection-available($collection || "/VRA_images")) then
        (
            (: update ACL for VRA_images collection  :)
            local:copy-user-ace($collection, $collection || "/VRA_images"),
            (: update ACL for resources in VRA_images   :)
            local:inherit-collection-user-acl-to-resources(xs:anyURI($collection || "/VRA_images"))
        )
    else
        ()

};
    
let $collection-path := $config:mods-commons
for $collection-name in xmldb:get-child-collections($collection-path)
return local:inherit-tamboti-collection-user-acl(xs:anyURI($collection-path || $collection-name || "/"))

