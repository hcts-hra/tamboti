xquery version "3.0";

import module namespace image-link-generator="http://hra.uni-heidelberg.de/ns/tamboti/modules/display/image-link-generator" at "../../modules/display/image-link-generator.xqm";

let $image-uuid := request:get-parameter("uuid", "")
let $service-name := request:get-parameter("service-name", "tamboti-thumbnail")
return 
    if(not($image-uuid = "")) then
        image-link-generator:generate-href($image-uuid, $service-name)
    else
        ""
