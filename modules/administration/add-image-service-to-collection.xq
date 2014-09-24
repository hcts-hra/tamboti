xquery version "3.0";
declare namespace vra="http://www.vraweb.org/vracore4.htm";

let $collection := "path/to/collection"
let $image-service-prefix := "service-prefix"

for $image-vra at $pos in collection($collection || "/VRA_images")
    let $image-href := data($image-vra//vra:image/@href)
    return 
        if(contains($image-href, "://")) then
            (: ToDo: if there is already an image service prefix, remove it :)
            ()
        else
            let $href-new := $image-service-prefix || "://" || $image-href
            return
(:                $href-new:)
                update value $image-vra//vra:image/@href with $href-new