xquery version "3.0";

import module namespace functx="http://www.functx.com";
import module namespace im4xquery="http://expath.org/ns/im4xquery" at "java:org.expath.exist.im4xquery.Im4XQueryModule"; 
import module namespace security = "http://exist-db.org/mods/security" at "../search/security.xqm";
import module namespace iiif-functions = "http://hra.uni-heidelberg.de/ns/iiif-functions" at "iiif-functions.xqm";
import module namespace http="http://expath.org/ns/http-client";

declare namespace xhtml="http://www.w3.org/1999/xhtml";

declare option exist:serialize "method=text media-type=text/plain omit-xml-declaration=yes";

declare variable $services := doc("../configuration/services.xml");
declare variable $mime-to-convert := ("image/tiff");

declare function local:server-capabilities($service-protocol as node()?) {
    if(not($service-protocol)) then 
        let $log := util:log("DEBUG", "no service prot")
        return
            map{
                "resize"    := false(),
                "crop"      := false(),
                "rotate"    := false()
    (:            "crop-pct"  := false():)
            }
    else
        
        let $full-parameter-url := $service-protocol/call[@type="full-parameter"]/url/string()
        let $capable-cropping :=
            if (contains($full-parameter-url, "[region]")) then
                true()
            else
                false()
        let $capable-resize := 
            if (contains($full-parameter-url, "[size]")) then
                true()
            else
                false()

(:            let $capable-cropping-pct :=:)
(:                if (contains($full-parameter-url, "[region_pct]")) then:)
(:                    true():)
(:                else:)
(:                    false():)
        let $capable-rotating :=
            if (contains($full-parameter-url, "[rotate]")) then
                true()
            else
                false()
    
        return
            map{
                "resize"    := $capable-resize,
                "crop"      := $capable-cropping,
                "rotate"    := $capable-rotating
(:                "crop-pct"  := $capable-cropping-pct:)
            }
};

declare function local:get-service-url($iiif-parameters as node(), $service-protocol as node()?) {
    let $call := $service-protocol/call[@type="full-parameter"]
    let $url := $call/url/string()
    let $do-crop := ($iiif-parameters//image-request-parameters/region/full/string() = "")
    let $do-resize := ($iiif-parameters//image-request-parameters/size/full/string() = "")
    let $do-rotate := not($iiif-parameters//image-request-parameters/rotation/degrees/string() = "0")

    let $capabilities := local:server-capabilities($service-protocol)
    
    let $local-crop := 
        (: if call says "crop" and remote server is not able   :)
        if($do-crop and not($capabilities("crop"))) then
            true()
        else
            false()
    let $log := util:log("DEBUG", "local-crop: " || $local-crop )

    let $local-resize := 
        (: if "crop" and if remote server is not able or cropping will also be done locally :)
        if($do-resize and ($local-crop or not($capabilities("resize")))) then
            true()
        else
            false()

    let $log := util:log("DEBUG", "local-resize: " || $local-resize )

    let $local-rotate := 
        (: if "crop" and if remote server is not able or resizing wil also  be done locally:)
        if($do-rotate and ($local-resize or not($capabilities("rotate")))) then
            true()
        else
            false()

    let $log := util:log("DEBUG", "local-rot: " || $local-rotate )

    (:  replace the url keys for size, rotate respective the IIIF order - surpass if an earlier conversion will be done locally :)
    let $url := 
        (: if "do resize" and cropping will be done locally, do resize locally as well :)
        if ($do-resize and $local-crop and $capabilities("resize")) then
            let $queryString := $call/replacements/replace[@key="size"]/string()
            (: use the full parameter for resizing :)
            let $iiif-parameters := 
                <iiif-parameters>
                    <image-request-parameters>
                        <size>
                            <full>full</full>
                        </size>
                    </image-request-parameters>
                </iiif-parameters>
                
            let $changeFrom := "\[size\]"
            let $changeTo := util:eval($queryString)
            return 
                replace($url, $changeFrom, $changeTo)
        else $url

    let $url := 
        (: if "do rotate" and resizing will be done locally, do rotate locally as well :)
        if ($do-resize and $local-crop and $capabilities("rotate")) then
            let $queryString := $call/replacements/replace[@key="rotate"]/string()
            let $iiif-parameters := 
                <iiif-parameters>
                    <image-request-parameters>
                        <rotation>
                            <degrees>0</degrees>
                        </rotation>
                    </image-request-parameters>
                </iiif-parameters>
            
            let $changeFrom := "\[rotate\]"
            let $changeTo := util:eval($queryString)
            return 
                replace($url, $changeFrom, $changeTo)
        else
            $url
    (: only let remote server resize the image if it was not done locally       :)
    return $url
};


declare function local:get-info($image-VRA as node(), $iiif-parameters as node()?, $service-protocol as node()?, $image-server as node()?) {
    (: if $service-protocol is set, server is capable of sending it :)
    let $info-url := $service-protocol/call[@type="info"]/url/string()
    return 
        if ($info-url) then
            (: first replace the server definitons :)
        
            (: replace the service definitions:)
            let $replacement-definitions := $image-server/uri[@name="general"]/replacements
        
            let $info-url := local:replace-url-keys($image-VRA, $iiif-parameters, $info-url, $replacement-definitions)
        
            let $remote-id-url := xmldb:decode-uri(xs:anyURI(functx:substring-before-last($info-url, "/")))
            let $self-id-url := xs:anyURI(functx:substring-before-last(request:get-url() || "?" || request:get-query-string(), "/"))
        
            let $useless := util:log("DEBUG", $self-id-url || " " || $remote-id-url)
        
            let $response := http:send-request(<http:request method="GET"/>, $info-url)
            let $media-type := $response[1]/http:body/@media-type/string()
            let $header := response:set-header("Content-Type", $media-type)
            let $header := response:set-header("Content-Disposition", "inline; filename=""info.json""")
            let $json-response-string := util:binary-to-string($response[2])
        
            return
                replace($json-response-string, functx:escape-for-regex($remote-id-url), $self-id-url)

        else 
            let $parameters :=     
                <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
                    <output:method value="json"/>
                    <output:media-type value="application/json"/>
                    <output:prefix-attributes value="yes"/>
                </output:serialization-parameters>
(:            let $useless := util:log("DEBUG", $self-id-url || " " || $remote-id-url):)
(:            let $header := response:set-header("Content-Type", "application/json"):)
            let $uuid := $iiif-parameters//identifier/string()
            let $iiif-parameters := iiif-functions:parse-iiif-call("/" || $uuid || "/full/full/0/default.jpg")
            let $binary := local:get-binary-data($image-VRA, $service-protocol, $iiif-parameters, $image-server)
            let $iiif-info-xml := iiif-functions:info($binary, $iiif-parameters)
(:            let $log := util:log("INFO", $iiif-info-xml):)

            let $header := response:set-header("Content-Type", "application/json")
            let $header := response:set-header("Content-Disposition", "inline; filename=""info.json""")

            return 
                serialize($iiif-info-xml, $parameters)

};

declare function local:get-binary-data($image-VRA as node(), $service-protocol as node()?, $iiif-parameters as node(), $image-server as node()?) as xs:base64Binary{
    (: Since the IIIF calls have a defined order, the local converting "overwrites" the following steps after a missing capability :)
    (: eg. if a server is not able to crop, but the output should be a cropped image, resizing and rotating must not be done by the remote server but local :)

    let $server-capabilities := local:server-capabilities($service-protocol)
    let $binary :=
        if(empty($service-protocol)) then
            let $log := util:log("DEBUG", "get local binary")
            let $resource-uri := xs:anyURI(util:collection-name(root($image-VRA)))
            let $binary-name := $image-VRA/@href/string()
            let $binary-uri := xs:anyURI($resource-uri || "/" || $binary-name)
            let $useless := util:log("DEBUG", $binary-uri)
            return
                util:binary-doc($binary-uri)
        else

            (: first replace the server definitons :)
            let $binary-url := $service-protocol/call[@type="full-parameter"]/url/string()
            let $binary-url :=  local:get-service-url($iiif-parameters, $service-protocol)
            let $server-replacement-definitions := $service-protocol/call[@type="full-parameter"]/replacements
        
            let $binary-url := local:replace-url-keys($image-VRA, $iiif-parameters, $binary-url, $server-replacement-definitions)
        
            (: replace the service definitons :)
            let $service-replacement-definitions := $image-server/uri[@name="general"]/replacements
            let $binary-url := local:replace-url-keys($image-VRA, $iiif-parameters, $binary-url, $service-replacement-definitions)
            
            let $useless := util:log("DEBUG", "binary-URL: " ||  $binary-url)
            let $response := http:send-request(<http:request method="GET"/>, $binary-url)
            return
              data($response[2])

    (: IIIF-Specifications on order of implementation: Region THEN Size THEN Rotation THEN Quality THEN Format:)

    (: if service was not capable of cropping, crop:)
    let $conv-call := 
        if(not($server-capabilities("crop"))) then
            let $log := $server-capabilities("crop")
            let $useless := util:log("DEBUG", "local cropping")
            let $conv-call := local:crop-local-parameter($iiif-parameters)
            let $conv-call := $conv-call || " " || local:resize-local-parameter($iiif-parameters)
            let $conv-call := $conv-call || " " || local:rotate-local-parameter($iiif-parameters)
            return 
                $conv-call
        else
        (: if service was not capable of resizing, resize:)
        if(not($server-capabilities("resize"))) then
            let $useless := util:log("DEBUG", "local scaling")
            let $conv-call := local:resize-local-parameter($iiif-parameters)
            let $conv-call := $conv-call || " " || local:rotate-local-parameter($iiif-parameters)
            return 
                $conv-call
            else
            (: if service was not capable of rotating, rotate:)
            if(not($server-capabilities("rotate"))) then
                let $useless := util:log("DEBUG", "local rotating")
                let $conv-call := local:rotate-local-parameter($iiif-parameters)
                return 
                    $conv-call
            else
                ""
    let $useless := util:log("DEBUG", "conv-call:" || $conv-call)
    return 
        if ($conv-call = "") then
            $binary
        else
            im4xquery:convert($binary, $conv-call)
};

declare function local:resize-local-parameter($iiif-parameters as node()) as xs:string {
    (: resize, but resizing is not provided by that service?:)
    if ($iiif-parameters/image-request-parameters/size/full/string() = "") then
        let $parameters := 
            let $width :=
                $iiif-parameters/image-request-parameters/size/x/string()
            let $height :=
                $iiif-parameters/image-request-parameters/size/y/string()
            return
                $width || "x" || $height

        let $call := "-resize " || $parameters
        let $useless := util:log("INFO", "local resize call: " || $call)
        return
            $call
    else
        ""
};

declare function local:crop-local-parameter($iiif-parameters as node()) as xs:string {

    let $region-parameters := $iiif-parameters/image-request-parameters/region
    (: full? then do nothing :)
    return
        if ($region-parameters/full/string() = "full") then
            ""
        else
            (: region by percentage? :)
            if($region-parameters/pct/string() = "true") then
                (: TBD :)
                ""
            (: region by x,y, width and height:)
            else
                let $x := $region-parameters/x/string()
                let $y := $region-parameters/y/string()
                let $w := $region-parameters/w/string()
                let $h := $region-parameters/h/string()
                let $useless := util:log("DEBUG", "local crop: convert -crop " || $x || "x" || $y || "+" || $w || "+" || $h)
                return
                    "-crop " || $w || "x" || $h || "+" || $x || "+" || $y || "!" || " -background none -flatten"

};

declare function local:rotate-local-parameter($iiif-parameters as node()) as xs:string {

    let $rotation-parameters := $iiif-parameters/image-request-parameters/rotation
    let $degrees := $rotation-parameters/degrees/string()
    return
        (: "0" then do nothing :)
        if ($degrees = "0") then
            ""
        else
            (: rotate by degree? :)
            let $useless := util:log("DEBUG", "local rotate: convert -rotate " || $degrees)
            return
                "-rotate " || $degrees
};

declare function local:replace-url-keys($vra-image as node(), $iiif-parameters as node(), $url as xs:string, $replacements as node()?) {
    let $replace-map := map:new(
        for $variable in $replacements/replace
            let $key := $variable/@key/string()
            let $queryString := $variable/text()
            let $changeTo := util:eval($queryString)
            let $changeFrom := "\[" || $key || "\]"
            return
                map:entry($changeFrom, $changeTo)
    )

    let $from-seq := map:keys($replace-map)
    let $to-seq :=
        for $from in $from-seq
            let $useless := util:log("DEBUG", $from || " = " || $replace-map($from))
            let $to-value := 
                if ($replace-map($from)) then
                    xs:string($replace-map($from))
                else
                    xs:string("")
            return
                $to-value

    let $return :=
        functx:replace-multi($url, $from-seq, $to-seq)
    return 
       $return

};

let $width := request:get-parameter("width", () )
let $height := request:get-parameter("height", () )

let $query-string := request:get-query-string()

let $schema := request:get-parameter("schema", "local")
let $call := request:get-parameter("call", "")

let $iiif-parameters :=
    (: if it's a IIIF call get the IIIF infos :)
    if($schema = "IIIF") then
        iiif-functions:parse-iiif-call($call)
    (: no standardized protocol means 'historical' local call :)
    else
        let $size := 
            if($width or $height) then
                "!" || $width || "," || $height
            else
                "full"
        let $call := request:get-parameter("uuid", "") || "/full/" || $size || "/0/default.jpg"
        let $log := util:log("DEBUG", $call)
        return 
            iiif-functions:parse-iiif-call($call)

let $imageUUID := 
        $iiif-parameters/identifier/string()

let $image-VRA := security:get-resource($imageUUID)

return 
    if (empty($image-VRA)) then
        let $header := response:set-header("content-type", "text/html")
        return
            $imageUUID || " not found"
            
    (:  valid schema calls:)

    else
        (: get href attribute of vra:image where the image service is defined as a prefix :)
        let $image-href := data($image-VRA/@href)

        (: get the image service name :)
        let $image-service-name :=
            if (fn:substring-before($image-href, "://") = "") then
                "exist-internal"
            else
                fn:substring-before($image-href, "://")
                
        (: get the filename :)
        let $useless := util:log("DEBUG",  "ImageServiceName: " || $image-service-name)

        let $filename := 
            if ($image-service-name = "exist-internal") then
                $image-href
            else
                substring-after($image-href, "://")

        (: get image service definition :)
        let $image-server := $services//service/image-service[@name=$image-service-name]
        
        (: get the service protocol :)
        let $service-protocol-name := $image-server/uri[@name="general"]/@service-protocol/string()
        let $service-protocol := $services/services/imageServiceProtocolDefinitions/serviceProtocol[@name=$service-protocol-name]
        let $useless := util:log("DEBUG", "service-protocol-name: " || $service-protocol-name)
        let $useless := util:log("DEBUG", "full-parameters: " || $service-protocol/call[@type="full-parameter"]/url/string())
        (: if the IIIF info is wanted :)
        return
            if (root($iiif-parameters)/iiif-info/identifier) then
                let $useless := util:log("DEBUG", "GETTING INFO")
                let $iiif-info := local:get-info($image-VRA, $iiif-parameters, $service-protocol, $image-server)
                return
                    $iiif-info
                    
            (: else get the binary:)
            else
                let $useless := util:log("DEBUG", "GETTING BINARY DATA")
                let $binary-data := local:get-binary-data($image-VRA, $service-protocol, $iiif-parameters, $image-server)
    
                let $metadata := contentextraction:get-metadata($binary-data)
        
                (: What is the content type after all? :)
                let $mime-type := $metadata//xhtml:meta[@name="Content-Type"]/@content/string()
        
                (: if format listed in $mime-to-convert, convert into jpg :)
                let $binary-data :=
                    if($mime-type = $mime-to-convert) then
                        let $useless := util:log("DEBUG", "convert")
                        return
                            im4xquery:convert2jpg($binary-data)
                    else
                        $binary-data
        
                let $useless := util:log("DEBUG", "mime-before: " || $mime-type)
        
                let $mime-type :=
                    if($mime-type = $mime-to-convert) then
                        "image/jpeg"
                    else
                        $mime-type
        
                let $useless := util:log("DEBUG", "mime: " || $mime-type)
        
                return
    
                    if (not(empty($binary-data))) then
                        let $header := response:set-status-code(200)
                            return
                                response:stream-binary($binary-data, $mime-type, functx:substring-before-last($filename, ".") || "." || functx:substring-after-last($mime-type, "/"))
                    else
                        let $header := response:set-status-code(400)
                        return
                            <div>error! {empty($binary-data)}</div>