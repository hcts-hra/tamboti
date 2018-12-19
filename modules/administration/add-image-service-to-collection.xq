xquery version "3.1";

declare namespace vra="http://www.vraweb.org/vracore4.htm";

declare variable $image-service-prefix := "prefix-for-imageservice";

declare function local:update-imageservice($collection as xs:anyURI, $recursive as xs:boolean) {
    for $image-vra at $pos in collection($collection || "/VRA_images")
        let $image-href := data($image-vra//vra:image/@href)
        let $log := util:log("INFO", $collection)
        return 
            if(contains($image-href, "://")) then
                (: if there is already an image service prefix, remove it :)
                let $image-href := substring-after($image-href, "://")
                let $href-new := $image-service-prefix || "://" || $image-href
                return
(:                    $href-new:)
                    update value $image-vra//vra:image/@href with $href-new            
            else
                let $href-new := $image-service-prefix || "://" || $image-href
                return
(:                    $href-new:)
                    update value $image-vra//vra:image/@href with $href-new
    ,
    if ($recursive) then
        for $subcol in xmldb:get-child-collections($collection)
        return
            if($subcol = "VRA_images") then
                ()
            else
                local:update-imageservice(xs:anyURI($collection || "/" || $subcol), $recursive)
    else
        ()
};


let $collection := xs:anyURI("/path/to/collection")

let $include-subcollection := true()

return 
    local:update-imageservice($collection, $include-subcollection)
