xquery version "3.0";

import module namespace image-service="http://hra.uni-heidelberg.de/ns/tamboti/image-service" at "image-service.xqm";
import module namespace functx="http://www.functx.com";
import module namespace content="http://exist-db.org/xquery/contentextraction" at "java:org.exist.contentextraction.xquery.ContentExtractionModule";

declare namespace xhtml="http://www.w3.org/1999/xhtml";

let $imageUUID := request:get-parameter("uuid", "")
let $width := request:get-parameter("width", "")

let $image-VRA := image-service:get-image-vra($imageUUID)
return 
    if (empty($image-VRA)) then
        $imageUUID || " not found"
    else
         (: parent collection should be obsolete if we got a common place to store all images:)
        let $parentCollection := functx:substring-before-last(base-uri($image-VRA), '/')
        let $image-filename := data($image-VRA/@href)
        let $image-binary-uri := $parentCollection || "/" || $image-filename
        let $image-binary-data := xs:base64Binary(util:binary-doc($image-binary-uri))
        let $image-metadata := contentextraction:get-metadata(util:binary-doc($image-binary-uri))
        (:let $image-binary-metadata := contentextraction:get-metadata($image-binary-data):)
        let $image-binary-mime := xmldb:get-mime-type(xs:anyURI($image-binary-uri))
(:        let $image-dimensions := map {  "height" := image:get-height($image-binary-data),:)
(:                                        "width":=  image:get-width($image-binary-data) }:)

        let $image-dimensions := map {  "height" := data($image-metadata//xhtml:meta[@name="tiff:ImageLength"]/@content),
                                        "width" := data($image-metadata//xhtml:meta[@name="tiff:ImageWidth"]/@content) }

        let $image-binary-data := xs:base64Binary(util:binary-doc($image-binary-uri))
        return  
        (:let $setContent-disposition := response:set-header("content-disposition", concat("attachment; filename=", $image-filename)):)
            if(not($width = "")) then
        (:        let $bin := xs:base64Binary(image:scale(util:binary-doc($image-binary-uri), (image:get-height(util:binary-doc($image-binary-uri)) , $width), $image-binary-mime)):)
                let $bin := xs:base64Binary(image:scale($image-binary-data, (xs:integer($image-dimensions("height")), xs:integer($width)), $image-binary-mime))
                return 
(:                    $image-dimensions("height"):)
(:                    $image-metadata:)
                    response:stream-binary($bin, $image-binary-mime, $image-filename)
            else
                response:stream-binary($image-binary-data, $image-binary-mime, $image-filename)
