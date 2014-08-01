xquery version "3.0";
declare namespace vra="http://www.vraweb.org/vracore4.htm";

for $image-vra at $pos in collection("/db/resources/commons/Priya_Paul_Collection/VRA_images")
    let $image-href := data($image-vra//vra:image/@href)
    return 
        if(contains($image-href, "://")) then
            ()
        else
            let $href-new := "ppcol-service://" || $image-href
            return
(:                $href-new:)
                update value $image-vra//vra:image/@href with $href-new
