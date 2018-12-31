xquery version "3.0";
import module namespace functx = "http://www.functx.com";

let $ids := (
"w_57b05b6a-493f-4c9d-bf2e-2bcdd4ddc746",
"i_f47b60ee-65b5-459d-993d-81d191491f77",
"w_a942a880-bbc9-469d-ae7f-9477272064bb",
"i_ad083d66-6344-4e2a-a480-97102f0ffd24",
"w_f95aa364-b2a5-4074-a690-0eae417f992e",
"i_4541ce89-e112-4dfd-98b7-d960c8ee9085",
"w_6455442b-7475-49ed-9947-97ae2120334d",
"i_da09a4b8-5c88-4bd6-ad3c-87783cd70c8d",
"w_669167ae-e8cb-46c1-9919-8329a1326b76",
"i_bf68ac9b-96a3-467b-891c-0e0f34623042",
"w_e764c3b8-7f09-4380-af01-b6348db2780e",
"i_988888da-7ce2-4974-bfc8-bad3034cf458",
"w_f1e1a1fc-219b-4d37-b9d7-4c21a438e06a",
"i_1454a9c9-0aae-45c8-b90d-64d015322225",
"w_6e5589ca-da24-4a65-975e-4ec8ba96c26a",
"i_0b16d15b-34c4-4f7e-976f-8fb1506c5666",
"w_89d3c4ac-a9b0-4c4f-91eb-82a8c75cbdf9",
"i_f432fe01-181f-4065-a52e-0587f63903b3",
"w_d83af974-e8b7-491d-86cf-2e6e0b533c73",
"i_f53c46eb-e3d3-478e-a40e-65bfbf9a7ea1")



let $colName := xmldb:encode-uri("/db/data/users/simon.gruening@ad.uni-heidelberg.de/CCO-Samples")
let $col := collection($colName)
    
let $resource-uris := 
    for $res in $col//*[@id = $ids]
    let $uri := document-uri(root($res))
    return 
        $uri
let $zip := compression:zip($resource-uris, true())
return
    response:stream-binary($zip, "application/zip", "resources.zip")
    
(:    for $res in $resource-uris:)
(:        let $source-collection-uri := xs:anyURI(functx:substring-before-last($res, "/")):)
(:        let $target-collection-uri := "/db/tmp":)
(:        let $res-name := functx:substring-after-last($res, "/"):)
(:        return:)
(:            xmldb:copy($source-collection-uri, $target-collection-uri, $res):)
