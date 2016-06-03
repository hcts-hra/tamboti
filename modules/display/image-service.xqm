xquery version "3.0";

module namespace image-service="http://hra.uni-heidelberg.de/ns/image-service";

import module namespace http="http://expath.org/ns/http-client";
(:import module namespace httpclient="http://exist-db.org/xquery/httpclient";:)

import module namespace im4xquery="http://expath.org/ns/im4xquery" at "java:org.expath.exist.im4xquery.Im4XQueryModule"; 
import module namespace functx="http://www.functx.com";
import module namespace security = "http://exist-db.org/mods/security" at "../search/security.xqm";

import module namespace iiif-functions = "http://hra.uni-heidelberg.de/ns/iiif-functions" at "iiif-functions.xqm";

declare namespace vra="http://www.vraweb.org/vracore4.htm";

declare variable $image-service:services := doc("../configuration/services.xml");
declare variable $image-service:vra-data-root := xs:anyURI("/db/data");

declare function image-service:get-service-url($iiif-parameters as node(), $service-protocol as node()?) {
    let $call := $service-protocol/call[@type="full-parameter"]
    let $url := $call/url/string()
    let $do-crop := ($iiif-parameters//image-request-parameters/region/full/string() = "")
    let $do-resize := ($iiif-parameters//image-request-parameters/size/full/string() = "")
    let $do-rotate := not($iiif-parameters//image-request-parameters/rotation/degrees/string() = "0")

    let $capabilities := image-service:server-capabilities($service-protocol)
    
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

declare function image-service:server-capabilities($service-protocol as node()?) {
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

declare function image-service:get-binary-data($image-VRA as node(), $service-protocol as node()?, $iiif-parameters as node(), $image-server as node()?) as xs:base64Binary{
    (: Since the IIIF calls have a defined order, the local converting "overwrites" the following steps after a missing capability :)
    (: eg. if a server is not able to crop, but the output should be a cropped image, resizing and rotating must not be done by the remote server but local :)
    let $server-capabilities := image-service:server-capabilities($service-protocol)
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
            let $binary-url :=  image-service:get-service-url($iiif-parameters, $service-protocol)
            let $server-replacement-definitions := $service-protocol/call[@type="full-parameter"]/replacements
        
            let $binary-url := image-service:replace-url-keys($image-VRA, $iiif-parameters, $binary-url, $server-replacement-definitions)
        
            (: replace the service definitons :)
            let $service-replacement-definitions := $image-server/uri[@name="general"]/replacements
            let $binary-url := image-service:replace-url-keys($image-VRA, $iiif-parameters, $binary-url, $service-replacement-definitions)
            
            let $response := httpclient:get($binary-url, true(), ())
            let $mime := $response/httpclient:body/@mimetype/string()
            return
                $response/httpclient:body/data()
                

    (: IIIF-Specifications on order of implementation: Region THEN Size THEN Rotation THEN Quality THEN Format:)

    (: if service was not capable of cropping, crop:)
    let $conv-call := 
        if(not($server-capabilities("crop"))) then
            let $log := $server-capabilities("crop")
            let $useless := util:log("DEBUG", "local cropping")
            let $conv-call := local:crop-local-parameter($iiif-parameters)
            let $conv-call := $conv-call || " " || image-service:resize-local-parameter($iiif-parameters)
            let $conv-call := $conv-call || " " || image-service:rotate-local-parameter($iiif-parameters)
            return 
                $conv-call
        else
        (: if service was not capable of resizing, resize:)
        if(not($server-capabilities("resize"))) then
            let $useless := util:log("DEBUG", "local scaling")
            let $conv-call := image-service:resize-local-parameter($iiif-parameters)
            let $conv-call := $conv-call || " " || image-service:rotate-local-parameter($iiif-parameters)
            return 
                $conv-call
            else
            (: if service was not capable of rotating, rotate:)
            if(not($server-capabilities("rotate"))) then
                let $useless := util:log("DEBUG", "local rotating")
                let $conv-call := image-service:rotate-local-parameter($iiif-parameters)
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

declare function image-service:resize-local-parameter($iiif-parameters as node()) as xs:string {
    (: resize, but resizing is not provided by that service?:)
    if ($iiif-parameters/image-request-parameters/size/full/string() = "") then
        let $width :=
            if ($iiif-parameters/image-request-parameters/size/x/string()) then
                $iiif-parameters/image-request-parameters/size/x/string()
            else
                $iiif-parameters/image-request-parameters/size/y/string()
        let $height :=
            if ($iiif-parameters/image-request-parameters/size/y/string()) then
                $iiif-parameters/image-request-parameters/size/y/string()
            else
                $iiif-parameters/image-request-parameters/size/x/string()
        let $useless := util:log("DEBUG", "local resize " || " to w:" || $width || " h:" || $height)
        return
            "-resize " || $width || "x" || $height
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

declare function image-service:rotate-local-parameter($iiif-parameters as node()) as xs:string {

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

declare function image-service:replace-url-keys($vra-image, $iiif-parameters as item(), $url as xs:string, $replacements as node()?) {
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

declare function image-service:get-info($vra-image as item(), $iiif-parameters as item()) {
    let $image-uuid := $vra-image/@id/string()
    let $image-href := $vra-image/@href/string()
(:    let $useless := util:log("INFO", "info-url:" || $image-href):)

    (: get the image service name :)
    let $image-service-name :=
        if (fn:substring-before($image-href, "://") = "") then
            "exist-internal"
        else
            fn:substring-before($image-href, "://")

    let $image-server := $image-service:services//service/image-service[@name=$image-service-name]

    let $service-protocol-name := $image-server/uri[@name="general"]/@service-protocol/string()
    let $service-protocol := $image-service:services/services/imageServiceProtocolDefinitions/serviceProtocol[@name=$service-protocol-name]

    (: if $service-protocol is set, server is capable of sending it :)
    let $info-url := $service-protocol/call[@type="info"]/url/string()
    return
        if ($info-url) then
            (: replace the service definitions:)
            let $replacement-definitions := $image-server/uri[@name="general"]/replacements
        
            let $info-url := image-service:replace-url-keys($vra-image, $iiif-parameters, $info-url, $replacement-definitions)
            let $self-id-url := functx:substring-before-last(request:get-url(), "/")

            let $id-regex := '"@id"[ ]*:[ ]*"[^"]*"'
            (: construct the new @id part:)
            let $replace-with := '"@id" : "' || $self-id-url || '"'

            let $response := httpclient:get($info-url, false(), ())

            let $media-type := $response/httpclient:head/httpclient:header[@name="Content-Type"]/@value/string()
            let $json-response-string := util:binary-to-string(data($response/httpclient:body))
            let $header := response:set-header("Content-Type", $response/httpclient:body/@mimetype/string())
            
            let $replaced := replace($json-response-string, $id-regex, $replace-with)
            return
                $replaced
                

        else 
            (: it's an internally modified (cropped/resized...) resource, so create an own :)
            let $iiif-parameters := iiif-functions:parse-iiif-call(xmldb:encode-uri(xs:anyURI("/" || $image-uuid || "/full/full/0/default.jpg")))
            let $binary := image-service:get-binary-data($vra-image, $service-protocol, $iiif-parameters, $image-server)
            let $iiif-info-xml := iiif-functions:info($binary, $iiif-parameters)
            let $parameters := 
                <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
                    <output:method value="json"/>
                    <output:media-type value="text/javascript"/>
                    <output:prefix-attributes value="yes"/>
                </output:serialization-parameters>

            return
                serialize($iiif-info-xml, $parameters)

};