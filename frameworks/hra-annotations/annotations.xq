xquery version "3.1";

import module namespace hra-anno-framework = "http://hra.uni-heidelberg.de/ns/hra-anno-framework" at "/db/apps/tamboti/frameworks/hra-annotations/hra-annotations.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "/apps/tamboti/modules/search/security.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml";

declare variable $action external;
declare variable $iri external;
declare variable $htmldata external;


(:try {:)
    switch ($action)
        case "as-body-or-target" return
            let $variables :=   ( 
                (xs:QName("action"), "as-body-or-target"), 
                (xs:QName("iri"), $iri)
            )
            let $annos-array := hra-anno-framework:get-annotationsFor($iri, ("target", "body"), true())
            let $log := util:log("INFO", array:size($annos-array))
            return
                if (array:size($annos-array) > 0) then
                    let $annos-html := hra-anno-framework:serialize-annotations($annos-array, "canvas-editor")
                    return
                        $annos-html
                    else
                        <div/>

        case "save" return
            let $log := util:log("INFO", $action)
            let $log := util:log("INFO", request:get-parameter-names())
            let $log := util:log("INFO", $htmldata)

            return
(:                $htmldata:)
                hra-anno-framework:store-annotations($htmldata, false())
(:            let $anno-config-id := $data/div/@data-configid/string():)
(:            let $target-id := $data/div/xhtml:div[@class="target-label"]/@target-id/string():)
(:            return:)
(:(:                ():):)
(:                hra-anno-framework:generate-anno($data, $anno-config-id, $target-id):)
        default
            return ()
(:} catch * {:)
(:    let $log := util:log("ERROR", "Error: Request failed with exception: " ||  $err:code || ": " || $err:description):)
(:    return:)
(:        false():)
(:}:)

        
    