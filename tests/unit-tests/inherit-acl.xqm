xquery version "3.0";

module namespace inherit-acl="http://hra.uni-heidelberg.de/ns/tamboti/unit-tests/inherit-acl.xq";
import module namespace security="http://exist-db.org/mods/security" at "/db/apps/tamboti/modules/search/security.xqm";


(:declare function inherit-acl:copy-user-ace($source, $target) {:)
(:    (: first remove ACL on target :):)
(:    sm:clear-acl(xs:anyURI($target)),:)
(:    (: add each ACE from collection to target:):)
(:    for $ace in sm:get-permissions($source)//sm:ace:)
(:        let $username := $ace/@who:)
(:        let $allowed := if ($ace/@access_type = "ALLOWED") then :)
(:            true():)
(:        else :)
(:            false():)
(:        let $mode := $ace/@mode:)
(:        return :)
(:            sm:add-user-ace(xs:anyURI($target), $username, $allowed, $mode):)
(::)
(:    :)
(:};:)

declare function inherit-acl:inherit-collection-user-acl-to-resources($collection as xs:anyURI) {
    for $resource-name in xmldb:get-child-resources($collection)
        return
            (
                (: first remove ACL on resource :)
                sm:clear-acl(xs:anyURI($collection || "/" || $resource-name)),
                (: add each ACE from collection to resource:)
                security:duplicate-acl($collection, $collection || "/" || $resource-name)
            )
};

declare function inherit-acl:inherit-tamboti-collection-user-acl($collection as xs:anyURI) {
        
    (: update ACL for resources in parent collection  :)
    inherit-acl:inherit-collection-user-acl-to-resources(xs:anyURI($collection)),
    
    if (xmldb:collection-available($collection || "/VRA_images")) then
        (
            (: update ACL for VRA_images collection  :)
            sm:clear-acl(xs:anyURI($collection || "/VRA_images")),
            security:duplicate-acl($collection, $collection || "/VRA_images"),
            (: update ACL for resources in VRA_images   :)
            inherit-acl:inherit-collection-user-acl-to-resources(xs:anyURI($collection || "/VRA_images"))
        )
    else
        ()

};

(:let $collection-path := xs:anyURI("/resources/users/freizo-editor/"):)
(:return :)
(:    inherit-acl:inherit-tamboti-collection-user-acl($collection-path):)
