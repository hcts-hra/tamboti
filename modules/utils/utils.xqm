xquery version "3.0";

module namespace tamboti-utils = "http://hra.uni-heidelberg.de/ns/tamboti/utils";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace security="http://exist-db.org/mods/security" at "../../modules/search/security.xqm";

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace vra="http://www.vraweb.org/vracore4.htm";


declare function tamboti-utils:get-username-from-path($path as xs:string?) as xs:string? {
    let $substring-1 := substring-after($path, $config:users-collection || "/")
    
    return if (contains($substring-1, '/')) then substring-before($substring-1, "/") else $substring-1
};

declare function tamboti-utils:create-vra-image-collection($collection-uri as xs:anyURI) as xs:boolean {
    if (xmldb:collection-available($collection-uri || "/VRA_images")) then
        true()
    else
        try {
            xmldb:create-collection($collection-uri, "/VRA_images"),
                system:as-user($config:dba-credentials[1], $config:dba-credentials[2], 
                    (
                        sm:chown(xs:anyURI($collection-uri || "/VRA_images"), xmldb:get-owner($collection-uri)),
                        sm:chmod(xs:anyURI($collection-uri || "/VRA_images"), $config:collection-mode),
                        sm:chgrp(xs:anyURI($collection-uri || "/VRA_images"), $config:biblio-users-group),
                        security:duplicate-acl($collection-uri, $collection-uri || "/VRA_images")
                    )
                )
        } catch * {
            <error>Caught error {$err:code}: {$err:description}</error>
        }
};

declare function tamboti-utils:move-resource($resource-uri as xs:anyURI) {
    let $result :=
        system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
            let $resource-name := 
                switch ($resource-format)
                    (: VRA  :)
                    case "VRA" return
                        util:document-name(collection($source-collection)//vra:work[@id = $resource-id][1])
                    (: TEI :)
    (:                case "TEI" return:)
    (:                    util:document-name(collection($source-collection)//vra:work[@id = $resource-id][1]):)
                    (: default: MODS:)
                    default return 
                        util:document-name(collection($source-collection)//mods:mods[@ID = $resource-id][1])
            return
                try {
                        (: move resource       :)
                        (: if VRA we have to move image recods and binaries as well :)
                        if ($resource-format = "VRA") then 
                            try {
                                tamboti-utils:create-vra-image-collection($target-collection),
                                let $relations := collection($source-collection)//vra:work[@id = $resource-id][1]/vra:relationSet/vra:relation[@type="imageIs"]
                                let $vra-images-target-collection := $target-collection || "/VRA_images"
                                (: create VRA_images collection if needed :)
                                (: move each image record :)
                                for $relation in $relations
                                    let $image-uuid := data($relation/@relids)
                                    let $image-vra := collection($source-collection)//vra:image[@id = $image-uuid]
                                    let $image-resource-name := util:document-name($image-vra)
                                    let $binary-name := data($image-vra/@href)
                                    let $vra-images-source-collection := util:collection-name($image-vra)
                                    return
                                        (
                                            (: if binary available, move it as well :)
(:                                            util:log("INFO", "testing availability:"  || $vra-images-source-collection || "/" || $binary-name),:)
                                            if(util:binary-doc-available($vra-images-source-collection || "/" || $binary-name)) then
                                                (
(:                                                    util:log("INFO", "moving: " || $vra-images-source-collection || "/" || $binary-name),:)
                                                    xmldb:move($vra-images-source-collection, $vra-images-target-collection, $binary-name)
                                                    (: clear ACL and copy ACL from parent collection :)
(:                                                    sm:clear-acl($vra-images-target-collection || "/" || $binary-name),:)
(:                                                    security:duplicate-acl($vra-images-target-collection, $vra-images-target-collection || "/" || $binary-name):)
                                                )
                                            else
                                                util:log("INFO", "not available: " || $vra-images-source-collection || "/" || $binary-name)
                                            ,
                                            (: move image record :)
                                            xmldb:move($vra-images-source-collection, $vra-images-target-collection, $image-resource-name)
(:                                            util:log("INFO", "has-lock?" || xmldb:document-has-lock($vra-images-target-collection, $image-resource-name)),:)
                                            (: clear ACL and copy ACL from parent collection :)
(:                                            sm:clear-acl($vra-images-target-collection || "/" || $image-resource-name),:)
(:                                            security:apply-parent-collection-permissions($vra-images-target-collection || "/" || $image-resource-name):)

                                        )
                            } catch * {
                                util:log("INFO", "Error: move resource failed: " ||  $err:code || ": " || $err:description),
                                false()
                            }
                            else
                                true()
                        ,
                        xmldb:move($source-collection, $target-collection, $resource-name)
                        (: clear ACL and copy ACL from parent collection :)
(:                        sm:clear-acl($target-collection || "/" || $resource-name),:)
(:                        security:duplicate-acl($target-collection, $target-collection || "/" || $resource-name) :)

                } catch * {
                    util:log("INFO", "Error: move resource failed: " ||  $err:code || ": " || $err:description)
                }
        )
    return
        if($result) then
            <status id="moved" from="{$source-collection}">{$target-collection}</status>
        else
            ()

};