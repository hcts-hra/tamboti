xquery version "3.1";
declare namespace c="http://hra.uni-heidelberg.de/ns/tamboti/annotations/config";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
import module namespace config = "http://exist-db.org/mods/config" at "/db/apps/tamboti/modules/config.xqm";
import module namespace hra-anno-framework = "http://hra.uni-heidelberg.de/ns/hra-anno-framework" at "/db/apps/tamboti/frameworks/hra-annotations/hra-annotations.xqm";

let $parameters :=     
    <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
        <output:method value="json"/>
        <output:media-type value="application/json"/>
        <output:prefix-attributes value="yes"/>
    </output:serialization-parameters>


(:let $html := :)
(:<div class="target-container ui-widget ui-widget-content ui-corner-all ui-draggable ui-draggable-handle" data-configid="anno-config-1" data-annoidx="0" svg-document-id="uuid-5dffa05e-50fa-4a0e-bcdf-cba7e7a6668c" svg-element-id="uuid-0c91f875-cdbc-4b28-a3dc-d71b81fc51c9" svg-element-xpath="/svg[1]/rect[1]"><div target-id="target_1" class="target-label" xmlns="http://www.w3.org/1999/xhtml">Transkription<span class="ui-icon ui-icon-trash anno-delete"></span><span class="ui-icon ui-icon-notice anno-updated"></span></div><div class="target-short" xmlns="http://www.w3.org/1999/xhtml"><div style="border-bottom:1px dashed black"><div><span style="text-decoration: underline">Tamboti-Resource:</span></div><div><span><a href="/exist/apps/tamboti/modules/search/index.html?search-field=ID&amp;value=w_486e258f-2860-4c10-b8f3-0e28b145783f" target="_blank">w_486e258f-2860-4c10-b8f3-0e28b145783f</a></span></div></div><div style="font-weight:bold">Vorbereitungsarbeiten durch B</div></div><div class="target-detail" xmlns="http://www.w3.org/1999/xhtml" style="display: none;"><div><div>Vorbereitungsarbeiten durch Baufirma Streib</div><!--<img src="http://mirrors.creativecommons.org/presskit/icons/cc.large.png" width="150"/>--></div></div><div class="target-iri">http://localhost:8080/exist/apps/tamboti/api/resource/w_486e258f-2860-4c10-b8f3-0e28b145783f?/vra%3Avra/vra%3Awork/vra%3AinscriptionSet/vra%3Ainscription%5B2%5D</div><div class="target-footer" xmlns="http://www.w3.org/1999/xhtml" style="display: none;"><span>Transcription by Dirk Eller</span></div></div>:)

let $html := <div class="target-container ui-widget ui-widget-content ui-corner-all ui-draggable ui-draggable-handle" valid-drop=".//(svg:svg | svg:rect | svg:polyline | svg:g)" data-configid="anno-config-1" data-annotypeid="anno-type-1" svg-document-id="uuid-5dffa05e-50fa-4a0e-bcdf-cba7e7a6668c" svg-element-id="uuid-36cee47f-7ede-46d2-aebe-2a73d73be88d" svg-element-xpath="/svg[1]/rect[3]"><div class="label target-label">Transcription<span class="ui-icon ui-icon-trash anno-delete"></span><span class="ui-icon ui-icon-notice anno-updated"></span></div><div class="short target-short" style="border-bottom: 1px solid black;">1.) Mi 19.2.75 wird heizbarer </div><div class="detail target-detail" style="display: none;">1.) Mi 19.2.75 wird heizbarer moderner Bauwagen
angefahren. Miete einschl. Propangas- Heizung
150.- pro Monat + Transportkosten</div><div class="footer target-footer" style="display: none;">Transcription by Dirk Eller</div><div class="target-iri">http://localhost:8080/exist/apps/tamboti/api/resource/w_486e258f-2860-4c10-b8f3-0e28b145783f?/vra/work/inscriptionSet/inscription%5B5%5D</div></div>

(:let $config := doc("/db/data/tamboti/retrodig-config.xml"):)
(:let $target-query := $config//c:annotation[1]/c:targets/c:target[1]/c:generateAnnotation/c:query:)
(::)
(:let $json-map := util:eval($target-query/string()):)
(::)
let $header := response:set-header("Media-Type", "text/javascript")
let $header := response:set-header("Content-Type", "application/json")
let $header := response:set-header("Content-Disposition", "inline; filename=""info.json""")

return 
    try {
        system:as-user("admin", "Mdft2012", (
            let $anno-map := hra-anno-framework:generate-anno($html, "anno-config-1", "anno-type-1")
(:            let $log := util:log("INFO", "hier"):)
            return
                serialize($anno-map, $parameters)
        ))
    } catch * {
        let $log := util:log("ERROR", "Error: adding annotation failed with exception: " ||  $err:code || ": " || $err:description)
        return
            false()
    } 
(:    request:get-scheme() || "://" || request:get-server-name() || ":" || request:get-server-port() || $config:app-http-root:)
(:    <root>{$json-map}</root>:)
(:    datetime:timestamp-to-datetime(datetime:timestamp()):)

(:    hra-anno-framework:save-annotation($anno-map) :)
(:        hra-anno-framework:get-annotation("http://kjc-ws118.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/api/annotation/anno-43df7952-64bf-48cc-90ac-71bbf2579e66"):)
 
(:    "[" ||:)
(:    string-join(hra-anno-framework:as-target("http://kjc-ws118.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/api/resource/w_48572af2-b0c9-4194-9d86-30a6f1f31beb"), ","):)
(:    ||:)
(:    "]":)
 
(:    hra-anno-framework:as-target("http://kjc-ws118.kjc.uni-heidelberg.de:8080/exist/apps/tamboti/api/resource/w_48572af2-b0c9-4194-9d86-30a6f1f31beb"):)
