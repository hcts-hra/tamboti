xquery version "3.1";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
import module namespace functx="http://www.functx.com";

import module namespace hra-anno-framework = "http://hra.uni-heidelberg.de/ns/hra-anno-framework" at "/db/apps/tamboti/frameworks/hra-annotations/hra-annotations.xqm";

declare function local:wrapOutput($data, $testName) {
    <result class="{$testName}">
        {
            $data
        }
    </result>
};

(:let $tests := ("getTarget", "getAnnotations", "saveAnnotations"):)
let $tests := ("saveAnnotations")

return
    <div>
        {
            if ($tests = "getTarget") then
                let $annoConfigId := "anno-config-1"
                let $resourceId := "w_48572af2-b0c9-4194-9d86-30a6f1f31beb"
                let $result := hra-anno-framework:get-annotator-targets($resourceId, $annoConfigId)
                return
                    local:wrapOutput($result, "getTarget")
                    
            else
                ()
            ,
            if ($tests = "getAnnotations") then
                let $svgId := "uuid-5dffa05e-50fa-4a0e-bcdf-cba7e7a6668c"
                let $variables :=   ( 
                                        (xs:QName("action"), "as-body-or-target"), 
                                        (xs:QName("iri"), $svgId)
                                    )
                let $annos-array := hra-anno-framework:get-annotationsFor($svgId, ("target", "body"), true())
                let $annos-html := hra-anno-framework:serialize-annotations($annos-array, "canvas-editor")
                return
                    local:wrapOutput($annos-html, "getTarget")
            else
                ()
            ,
            if ($tests = "saveAnnotations") then
                let $parameters :=     
                    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
                        <output:method value="json"/>
                        <output:media-type value="application/json"/>
                        <output:prefix-attributes value="yes"/>
                    </output:serialization-parameters>

                    let $htmldata := 
                        <div class="annotations">
                            <div id="1" data-annoid="http://localhost:8080/exist/apps/tamboti/api/annotation/anno-786c3c58-3a56-48fd-b045-6fd2b78f66a5" data-delete="true" svg-element-xpath="//*[@id=2]" svg-element-id="2" svg-document-id="uuid-5dffa05e-50fa-4a0e-bcdf-cba7e7a6668c" data-resourceselector="/inscriptionSet/inscription[5]" data-configid="anno-config-1" data-targettypeid="anno-type-1" data-validdrop="" data-resourceid="w_486e258f-2860-4c10-b8f3-0e28b145783f" class="target-container ui-corner-all">
                                <div class="target-label">
                                    <span class="label-data">
                                        <div class="label">TESTANNOTATION</div>
                                    </span>
                                </div>
                                <div style="border-bottom: 1px solid black;" class="short target-short">
                                    <div style="font-weight:bold">SHORT</div>
                                </div>
                                <div style="display: none;" class="detail target-detail">
                                    <div>
                                        <div>DETAIL</div>
                                    </div>
                                </div>
                                <div style="display: none;" class="footer target-footer">
                                    <span>FOOTER</span>
                                </div>
                            </div>
<!--                            <div id="2" svg-element-xpath="//*[@id=1]" svg-element-id="1" svg-document-id="uuid-5dffa05e-50fa-4a0e-bcdf-cba7e7a6668c" data-resourceselector="/inscriptionSet/inscription[6]" data-configid="anno-config-1" data-targettypeid="anno-type-2" data-validdrop="" data-resourceid="w_486e258f-2860-4c10-b8f3-0e28b145783f" class="target-container ui-corner-all">
                                <div class="target-label">
                                    <span class="label-data">
                                        <div class="label">ANNO TYPE 2</div>
                                    </span>
                                </div>
                                <div style="border-bottom: 1px solid black;" class="short target-short">
                                    <div style="font-weight:bold">SHORT</div>
                                </div>
                                <div style="display: none;" class="detail target-detail">
                                    <div>
                                        <div>DETAIL</div>
                                    </div>
                                </div>
                                <div style="display: none;" class="footer target-footer">
                                    <span>FOOTER</span>
                                </div>
                            </div>
                            <div id="3" svg-element-xpath="//*[@id=1]" svg-element-id="1" svg-document-id="uuid-5dffa05e-50fa-4a0e-bcdf-cba7e7a6668c" data-resourceselector="/inscriptionSet/inscription[6]" data-configid="anno-config-1" data-targettypeid="anno-type-2" data-validdrop="" data-resourceid="w_48572af2-b0c9-4194-9d86-30a6f1f31beb" class="target-container ui-corner-all">
                                <div class="target-label">
                                    <span class="label-data">
                                        <div class="label">ANNO TYPE 2</div>
                                    </span>
                                </div>
                                <div style="border-bottom: 1px solid black;" class="short target-short">
                                    <div style="font-weight:bold">SHORT</div>
                                </div>
                                <div style="display: none;" class="detail target-detail">
                                    <div>
                                        <div>DETAIL</div>
                                    </div>
                                </div>
                                <div style="display: none;" class="footer target-footer">
                                    <span>FOOTER</span>
                                </div>
                            </div>-->
                        </div>
                        
(:                    let $header := response:set-header("Media-Type", "text/javascript"):)
(:                    let $header := response:set-header("Content-Type", "application/json"):)
(:                    let $header := response:set-header("Content-Disposition", "inline; filename=""info.json"""):)

                    return 
                        let $anno-map := util:eval(xs:anyURI("/db/apps/tamboti/frameworks/hra-annotations/annotations.xq"), false(), 
                            (
                                (xs:QName("action"), "save")
                            )
                        )
(:                        let $anno-map := hra-anno-framework:generate-anno($html, "anno-config-1", "anno-type-1"):)
            (:            let $log := util:log("INFO", "hier"):)
                        return
                            $anno-map
            else
                ()
        }
    </div>