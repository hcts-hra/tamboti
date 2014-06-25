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

declare function vra-hra-framework:move-resource($resource-id as xs:string, $destination-collection as xs:string) as element(status)+ {
    
    let $resource := collection($config:mods-root-minus-temp)//vra:vra[vra:work[@id eq $resource-id]][1]
    let $resource-name := $resource-id || ".xml"    
    let $resource-collection := substring-before(base-uri($resource), $resource-name)
    let $move-record :=
        for $list-item in vra-hra-framework:get-vra-work-record-list($resource)
            let $resource-relative-path := substring-after($list-item, $resource-collection)
            
            return 
                (
                    if (starts-with($resource-relative-path, 'VRA_images'))
                    then (
                    	let $image-collection := xs:anyURI($destination-collection || "/VRA_images")
                    	return
                    		(
                    		    xmldb:create-collection($destination-collection, "VRA_images"),
                        	    sm:chgrp($image-collection, $config:biblio-users-group),
                        	    security:apply-parent-collection-permissions($image-collection),
                        	    xmldb:move($resource-collection || "/VRA_images/", $destination-collection || "/VRA_images", substring-after($resource-relative-path, 'VRA_images/')),
                        	    security:apply-parent-collection-permissions(xs:anyURI($destination-collection || "/VRA_images/" || substring-after($resource-relative-path, 'VRA_images/')))
                    		)
                    )
                    else (
                        xmldb:move($resource-collection, $destination-collection, $resource-relative-path),
                        security:apply-parent-collection-permissions(xs:anyURI($destination-collection || "/" || $resource-relative-path))
                    )
                )
                
    return <status moved="{$resource-name}" from="{$resource-collection}" to="{$destination-collection}" />
    
};
