xquery version "3.0";

module namespace vra-hra-framework = "http://hra.uni-heidelberg.de/ns/vra-hra-framework";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "../../modules/search/security.xqm";

declare namespace vra = "http://www.vraweb.org/vracore4.htm";

declare function vra-hra-framework:get-vra-work-record-list($work-record as element()) as xs:string+ {
    (
            base-uri($work-record),
            vra-hra-framework:get-vra-image-records-list($work-record)
    )
};

declare function vra-hra-framework:get-vra-image-records-list($work-record as element()) as xs:string+ {
    let $image-record-ids := $work-record//vra:relationSet/vra:relation[@type eq "imageIs"]/@relids/string()
    let $image-record-ids := tokenize($image-record-ids, ' ')
    return
        for $image-record-id in $image-record-ids
        let $image-record := collection($config:mods-root-minus-temp)/vra:vra[vra:image/@id eq $image-record-id]
        let $image-record-url := base-uri($image-record)
        let $image-url := resolve-uri($image-record/*/@href, $image-record-url)        
        return
            (
                base-uri($image-record),
                $image-url
            )
};

declare function vra-hra-framework:move-resource($source-collection as xs:anyURI, $target-collection as xs:anyURI, $resource-id as xs:string) as element(status) {
	let $resource-name := util:document-name(collection($source-collection)//vra:work[@id = $resource-id][1])
	let $result :=
        system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
            try {
                tamboti-utils:create-vra-image-collection($target-collection),
                let $relations := collection($source-collection)//vra:work[@id = $resource-id][1]/vra:relationSet//vra:relation[@type="imageIs"]
                let $vra-images-target-collection := $target-collection || "/VRA_images"
                (: create VRA_images collection, if needed :)
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
                            if(util:binary-doc-available($vra-images-source-collection || "/" || $binary-name)) then
                                (
                                    xmldb:move($vra-images-source-collection, $vra-images-target-collection, $binary-name),
                                    (: clear ACL and copy ACL and POSIX-rights from parent collection :)
                                    sm:clear-acl(xs:anyURI($vra-images-target-collection || "/" || $binary-name)),
                                    security:duplicate-acl($vra-images-target-collection, $vra-images-target-collection || "/" || $binary-name),
                                    security:copy-owner-and-group(xs:anyURI($vra-images-target-collection), xs:anyURI($vra-images-target-collection || "/" || $binary-name))
                                )
                            else
                                util:log("INFO", "not available: " || $vra-images-source-collection || "/" || $binary-name)
                            ,
                            (: move image record :)
                            xmldb:move($vra-images-source-collection, $vra-images-target-collection, $image-resource-name),
                            (: clear ACL and copy ACL and POSIX-rights from parent collection :)
                            sm:clear-acl(xs:anyURI($vra-images-target-collection || "/" || $image-resource-name)),
                            security:duplicate-acl($vra-images-target-collection, $vra-images-target-collection || "/" || $image-resource-name),
                            security:copy-owner-and-group(xs:anyURI($vra-images-target-collection), xs:anyURI($vra-images-target-collection || "/" || $image-resource-name))

                        )
            } catch * {
                util:log("INFO", "Error: move resource failed: " ||  $err:code || ": " || $err:description),
                false()
            }
            ,
            xmldb:move($source-collection, $target-collection, $resource-name)
            ,
            (: clear ACL and copy ACL and POSIX-rights from parent collection :)
            sm:clear-acl(xs:anyURI($target-collection || "/" || $resource-name))
            ,
            security:duplicate-acl($target-collection, $target-collection || "/" || $resource-name)
            ,
            security:copy-owner-and-group(xs:anyURI($target-collection), xs:anyURI($target-collection || "/" || $resource-name))
        )

    return
        if($result) then
            <status moved="{$resource-name}" from="{$source-collection}" to="{$target-collection}">{$target-collection}</status>
        else
            <status id="error">Error trying to move</status>
};
