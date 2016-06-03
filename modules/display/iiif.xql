xquery version "3.0";

import module namespace functx="http://www.functx.com";
import module namespace im4xquery="http://expath.org/ns/im4xquery" at "java:org.expath.exist.im4xquery.Im4XQueryModule"; 
import module namespace security = "http://exist-db.org/mods/security" at "../search/security.xqm";
import module namespace image-service="http://hra.uni-heidelberg.de/ns/image-service" at "image-service.xqm";
import module namespace iiif-functions = "http://hra.uni-heidelberg.de/ns/iiif-functions" at "iiif-functions.xqm";
import module namespace http="http://expath.org/ns/http-client";

declare namespace xhtml="http://www.w3.org/1999/xhtml";

declare variable $mime-to-convert := ("image/tiff", "image/png");
declare variable $local:ERROR := xs:QName("local:error");

let $cors := response:set-header("Access-Control-Allow-Origin", "*")
let $action := request:get-parameter("action", false())
let $image-uuid := request:get-parameter("image-uuid", "")
let $image-vra := security:get-resource($image-uuid)
let $full-iiif-call := request:get-parameter("full-iiif-call", "")
return
    try {
        let $iiif-parameters := iiif-functions:parse-iiif-call($full-iiif-call)
        return
            if (not($image-vra)) then
                let $header := response:set-status-code(404)
                return
                    error($local:ERROR, "Resource not found", "")

            else if ($action) then
                switch($action)
                    (: IIIF-INFO requested       :)
                    case "iiif-info" return
                            let $header := response:set-status-code(200)
(:                            let $header := response:set-header("Content-Type", "text/javascript"):)
                            let $header := response:set-header("Content-Type", "application/ld+json")
                            let $header := response:set-header('Content-Disposition', 'inline; filename="info.json"')
                            return
                                image-service:get-info($image-vra)
                    case "iiif-binary" return
                        let $image-href := $image-vra/@href/string()
                        let $image-service-name :=
                            if (fn:substring-before($image-href, "://") = "") then
                                "exist-internal"
                            else
                                fn:substring-before($image-href, "://")
                        
                        (: get the filename :)
                        let $filename := 
                            if ($image-service-name = "exist-internal") then
                                $image-href
                            else
                                substring-after($image-href, "://")
        
                        (: get image service definition :)
                        let $image-server := $image-service:services//service/image-service[@name=$image-service-name]
                        
                        (: get the service protocol :)
                        let $service-protocol-name := $image-server/uri[@name="general"]/@service-protocol/string()
                        let $service-protocol := $image-service:services/services/imageServiceProtocolDefinitions/serviceProtocol[@name=$service-protocol-name]           
                        let $iiif-parameters := iiif-functions:parse-iiif-call($full-iiif-call)
        
                        let $binary-data := image-service:get-binary-data($image-vra, $service-protocol, $iiif-parameters, $image-server)
        
                        (: ToDo: What is the content type after all? -> deactivated due to performance:)
                        let $metadata := contentextraction:get-metadata($binary-data)
                        let $mime-type := $metadata//xhtml:meta[@name="Content-Type"]/@content/string()
                        (: image/jpeg   *.jpeg *.jpg *.jpe:)

                        (: if format listed in $mime-to-convert, convert into jpg :)
                        let $binary-data :=
                            if($mime-type = $mime-to-convert) then
                                let $useless := util:log("DEBUG", "convert")
                                return
                                    im4xquery:convert2jpg($binary-data)
                            else
                                $binary-data
                
                        let $mime-type :=
                            if($mime-type = $mime-to-convert) then
                                "image/jpeg"
                            else
                                $mime-type
                        return
                            if (not(empty($binary-data))) then
                                let $header := response:set-status-code(200)
                                    return
                                        response:stream-binary($binary-data, $mime-type, functx:substring-before-last($filename, ".") || "." || functx:substring-after-last($mime-type, "/"))
                            else
                                <div>error! empty $binary-data</div>
                            
                    default return
                        <div>error!</div>
            else
                <div>error!</div>
        
    } catch * {
        let $header := response:set-status-code(400)
        return 
            <error>Caught error {$err:code}: {$err:description}. Data: {$err:value}</error>
    }