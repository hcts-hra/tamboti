xquery version "3.0";

import module namespace image-service="http://hra.uni-heidelberg.de/ns/tamboti/image-service" at "image-service.xqm";
import module namespace functx="http://www.functx.com";
import module namespace content="http://exist-db.org/xquery/contentextraction" at "java:org.exist.contentextraction.xquery.ContentExtractionModule";

declare namespace xhtml="http://www.w3.org/1999/xhtml";



(: Workaround for integration in current Image-Service-call in tamboti :)
(:tamboti also sents: ?width=40&height=40&crop_type=middle :)

let $request-string := replace(request:get-query-string(), "\?", "&amp;")
let $request-parameters := tokenize($request-string, "&amp;")

(:let $imageUUID := request:get-parameter("uuid", ""):)
(:let $width := request:get-parameter("width", ""):)
let $parameters := map:new(
    for $param in $request-parameters
        return
            map:entry(substring-before($param, "="), substring-after($param, "="))
)

let $imageUUID := $parameters("uuid")
let $width := $parameters("width")

let $image-VRA := image-service:get-image-vra($imageUUID)
 (: parent collection should be obsolete if we got a common place to store all images:)
let $parentCollection := functx:substring-before-last(base-uri($image-VRA), '/')
let $image-filename := data($image-VRA/@href)
let $image-binary-uri := $parentCollection || "/" || $image-filename
let $image-binary-data := xs:base64Binary(util:binary-doc($image-binary-uri))
(:let $image-binary-metadata := contentextraction:get-metadata($image-binary-data):)
let $image-binary-mime := xmldb:get-mime-type(xs:anyURI($image-binary-uri))
let $image-dimensions := map {  "height" := image:get-height($image-binary-data),
                                "width":=  image:get-width($image-binary-data) }

let $image-binary-data := xs:base64Binary(util:binary-doc($image-binary-uri))
return 
(:let $setContent-disposition := response:set-header("content-disposition", concat("attachment; filename=", $image-filename)):)
    if(not(empty($width))) then
(:        let $bin := xs:base64Binary(image:scale(util:binary-doc($image-binary-uri), (image:get-height(util:binary-doc($image-binary-uri)) , $width), $image-binary-mime)):)
        let $bin := xs:base64Binary(image:scale($image-binary-data, ( $image-dimensions("height"), $width), $image-binary-mime))
        return 
            response:stream-binary($bin, $image-binary-mime, $image-filename)
    else
        response:stream-binary($image-binary-data, $image-binary-mime, $image-filename)
