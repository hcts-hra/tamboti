xquery version "3.1";

declare namespace vra = "http://www.vraweb.org/vracore4.htm";
declare default element namespace "http://www.vraweb.org/vracore4.htm";

let $collection-path := xs:anyURI("/data/commons/Faizulloev/")
let $image-collection-path := $collection-path || "VRA_images"

let $image-numbers := collection($image-collection-path)//vra:title/text()
let $processed-image-numbers :=
    for $image-number in $image-numbers
    
    return replace($image-number, "^(.*)(\d{3})(.*)$", "$2")
let $processed-image-numbers := distinct-values($processed-image-numbers)

return
    for $processed-image-number in $processed-image-numbers
    let $main-image-record-id := collection($image-collection-path)//vra:image[contains(.//vra:title, $processed-image-number || 'a')]/@id
    let $image-record-ids := collection($image-collection-path)//vra:image[contains(.//vra:title, $processed-image-number) and not(contains(.//vra:title, $processed-image-number || 'a'))]/@id
    
    let $main-work-record := collection($collection-path)//vra:work[.//vra:relation/@relids = $main-image-record-id]
    let $main-work-record-id := $main-work-record/@id
    let $process-main-record := (
        (: delete the referneces to secondary work records from the main work record :)
        update delete $main-work-record//vra:relation[starts-with(@relids, 'w_')]
        ,
        for $image-record-id in $image-record-ids
        
        return (
            (: insert reference to the secondary image record into the main work record :)
            update insert <relation pref="false" relids="{$image-record-id}" source="Tamboti" type="imageIs">general view</relation> following $main-work-record//vra:relation[@relids = $main-image-record-id] 
            ,
            (: update the reference to the main work record into the secondary image record :)
            update replace collection($image-collection-path)//vra:image[@id = $image-record-id]//vra:relation/@relids with $main-work-record-id
            ,
            (: delete the secondary work record :)
            let $work-record-id := collection($collection-path)//vra:work[@id != $main-work-record-id and .//vra:relation/@relids = $image-record-id]/@id
            
            return xmldb:remove($collection-path, $work-record-id || ".xml")
        )
    )

    
    return $process-main-record