xquery version "3.1";

import module namespace functx="http://www.functx.com";
import module namespace im4xquery="http://expath.org/ns/im4xquery" at "java:org.expath.exist.im4xquery.Im4XQueryModule"; 
import module namespace security = "http://exist-db.org/mods/security" at "../search/security.xqm";
import module namespace image-service="http://hra.uni-heidelberg.de/ns/image-service" at "image-service.xqm";
import module namespace iiif-functions = "http://hra.uni-heidelberg.de/ns/iiif-functions" at "iiif-functions.xqm";
import module namespace http="http://expath.org/ns/http-client";

declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace xhtml="http://www.w3.org/1999/xhtml";

declare variable $mime-to-convert := ("image/tiff", "image/png");
declare variable $local:ERROR := xs:QName("local:error");
declare variable $local:UNAUTORIZED := xs:QName("local:unautorized");
declare variable $local:NOT_FOUND := xs:QName("local:not_found");

declare variable $local:json-serialize-parameters :=
    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
        <output:method value="json"/>
        <output:media-type value="text/javascript"/>
    </output:serialization-parameters>;

let $cors := response:set-header("Access-Control-Allow-Origin", "*")
let $action := request:get-parameter("action", false())
let $image-uuid := request:get-parameter("image-uuid", "")
let $full-iiif-call := request:get-parameter("full-iiif-call", "")

(:let $session := session:get-id():)
return
    try {
        let $iiif-parameters := iiif-functions:parse-iiif-call($full-iiif-call)
        let $image-vra := collection(("/db/data/commons", "/db/data/users"))//vra:image[@id=$image-uuid]
(:
        let $log := util:log("INFO", "SERVER NAME: " || request:get-server-name())
        let $log := util:log("INFO", request:get-cookie-names())
        let $log := util:log("INFO", request:get-effective-uri())
        let $log := util:log("INFO", request:get-header-names())
:)

        (: check for valid auth cookie :)
        let $cookie-value := request:get-header("T-AUTH")
(:        let $log := util:log("INFO", "Auth token: " || $cookie-value) :)
        let $cookie-user := security:iiifauth-validate-cookie($cookie-value)
        let $user := 
            if ($cookie-user) then
(:            
                let $log := util:log("INFO", "COOKIE USER: " || $cookie-user)
                return
:)
                    $cookie-user
            else
                security:get-user-credential-from-session()[1]
        
(:        let $log := util:log("INFO", $user) :)
        return
            if($image-vra) then
                switch($action)
                    (: IIIF-INFO requested       :)
                    case "iiif-info" return
(:                        let $log := util:log("INFO", "********************* IIIF INFO *******************") :)
                        let $image-vra := collection(("/db/data/commons", "/db/data/users"))//vra:image[@id=$image-uuid]

                        let $header := response:set-header("Content-Type", "application/json")
                        let $header := response:set-header('Content-Disposition', 'inline; filename="info.json"')
                    
                        let $image-info := image-service:get-info($image-vra, $iiif-parameters)
(:                        let $log := util:log("INFO", request:get-uri()) :)
(:                        return:)
                        let $header := response:set-status-code(200)

                        let $image-info-json := parse-json($image-info)
(:                        let $log := util:log("INFO", $image-info):)
                        let $auth-service-json := 
                                map{
                                  "@context": "http://iiif.io/api/auth/0/context.json",
                                  "@id": "http://kjc-ws118.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/modules/login.html",
                                  "profile": "http://iiif.io/api/auth/0/login",
                                  "label": "Protected Material",
                                  "description": "You have to login into Tamboti to get access",
                                  "service": array{
                                    map{
                                      "@context": "http://iiif.io/api/auth/0/context.json",
                                      "@id": "https://wellcomelibrary.org/iiif/tokenterms",
                                      "profile": "http://iiif.io/api/auth/0/token"
                                    },
                                    map{
                                      "@context": "http://iiif.io/api/auth/0/context.json",
                                      "@id": "https://wellcomelibrary.org/iiif/logout",
                                      "profile": "http://iiif.io/api/auth/0/logout",
                                      "label": "Log out of Tamboti",
                                      "description": "Log out of Tamboti"
                                    }
                                  }
                                }

                        return
                            serialize(
                                map:new((
                                    $image-info-json
                                    ,
                                    map{
                                    "service":
                                        $auth-service-json
                                    }
                                    ))
                                    ,$local:json-serialize-parameters)

                    case "iiif-binary" return
                        (: check if user has access to the document:)
                        let $path := document-uri(root($image-vra))
                        let $user-access := security:user-has-access($user, $path, "r..")
(:                        let $log := util:log("INFO", $user || " has access to " || $path || ":" || $user-access) :)
                        
(:                                system:as-user(security:get-user-credential-from-session()[1],security:get-user-credential-from-session()[2],:)
(:                                    sm:has-access(document-uri(root($image-vra)), "r"):)
(:                                ):)
                        return
                            if($user-access) then
                                (: check for cookie :)
        (:                        let $image-vra := :)
        
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
                                        error($local:NOT_FOUND, "Binary not found", "")
                            else
                                error($local:UNAUTORIZED, "Unauthorized", "")
                    default return
                        error($local:ERROR, "IIIF Call not valid: " || $full-iiif-call , "")
            else
                error($local:NOT_FOUND, "Binary not found", "")
        
    } catch * {
        let $status-code :=
            switch ($err:code)
                case $local:ERROR return
                    500
                case $local:NOT_FOUND return
                    404
                case $local:UNAUTORIZED return
                    401
                default return
                    500
(:        let $log := util:log("INFO", "err-code:" || $err:code || " status code:" ||  $status-code):)
        let $header := response:set-status-code($status-code)
(:        let $log := util:log("INFO", <error>Caught error {$err:code}: {$err:description}. Data: {$err:value}</error>):)
        return 
            $err:description
    }