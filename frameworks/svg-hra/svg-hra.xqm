xquery version "3.1";

module namespace svg-hra-framework = "http://hra.uni-heidelberg.de/ns/svg-hra-framework";

import module namespace tamboti-common = "http://exist-db.org/tamboti/common" at "../../modules/tamboti-common.xql";
import module namespace vra-hra-framework = "http://hra.uni-heidelberg.de/ns/vra-hra-framework" at "../vra-hra/vra-hra.xqm";
import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "../../modules/search/security.xqm";
import module namespace hra-rdf-framework = "http://hra.uni-heidelberg.de/ns/hra-rdf-framework" at "../hra-rdf/hra-rdf-framework.xqm";

import module namespace functx="http://www.functx.com";

declare namespace svg="http://www.w3.org/2000/svg";
declare namespace oa="http://www.w3.org/ns/oa#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare variable $svg-hra-framework:THUMB_SIZE_FOR_GRID := 64;
declare variable $svg-hra-framework:THUMB_SIZE_FOR_GALLERY := 128;
declare variable $svg-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW := 256;
declare variable $svg-hra-framework:THUMB_SIZE_FOR_LIST_VIEW := 128;
declare variable $svg-hra-framework:record-type := "SVG";

declare variable $svg-hra-framework:motivations := map{
    "http://www.shared-canvas.org/ns/painting" := "canvas"
};

declare function svg-hra-framework:get-UUID($item as element()) {
    $item/@xml:id
};


declare function svg-hra-framework:toolbar($entry as node()) {
(:    let $useless := util:log("DEBUG", "isWritable:" || $isWritable):)
    let $collection := util:collection-name(root($entry))
    let $isWriteable := security:can-write-collection($collection)

    let $id := svg-hra-framework:get-UUID($entry)
    return
        <div class="actions-toolbar">
            <a target="_new" href="source.xql?id={$id}">
                <img title="View XML Source of Record" src="resources/images/script_code.png"/>
            </a>
            {
                (: if the item's collection is writable, display edit/delete and move buttons :)
                if ($isWriteable) then
                    (
                        <img title="Edit SVG Record" src="resources/images/page_edit.png"/>
                        ,
                        <a class="remove-resource" href="#{$id}"><img title="Delete Record" src="resources/images/delete.png"/></a>
                        ,
                        <a class="move-resource" href="#{$id}"><img title="Move Record" src="resources/images/shape_move_front.png"/></a>
                    )
                else
                    ()
            }
        </div>
};

(:~
: The <b>retrieve-svg:format-list-view</b> function returns the list view of a SVG record.
: @param $entry a SVG record
: @return an XHTML span.
:)
(:declare function svg-hra-framework:format-list-view($entry as element()) as element(span) {:)
declare function svg-hra-framework:format-list-view($entry as node(), $position as xs:string) {
    let $saved := false()
    let $uuid := $entry/@xml:id/string()
    let $type := functx:substring-after-last(xs:string(namespace-uri($entry)), "/")

    let $document-uri := document-uri(root($entry))
    let $filename := functx:substring-after-last($document-uri, "/")

    let $svg-viewBox := 
        if (exists($entry/@viewBox)) then
            tokenize($entry/@viewBox/string(), " ")
        else
            (0, 0, $entry/@width/string(), $entry/@height/string())

    (: ToDo: is it possible to have a title defined inside the svg? :)
    let $title := $filename

    let $test := 
        <div class="svg-record">
            <span>{$title}</span>
         </div>


    let $result :=
        <tr xmlns="http://www.w3.org/1999/xhtml" class="pagination-item list">
            <td><input class="search-list-item-checkbox" type="checkbox" data-tamboti-record-id="{$uuid}"/></td>
            <td class="pagination-number" style="vertical-align:middle">{$position}</td>
            <td class="actions-cell" style="vertical-align:middle">
                <a id="save_{$uuid}" href="#{$position}" class="save">
                    <img title="{if ($saved) then 'Remove Record from My List' else 'Save Record to My List'}" src="resources/images/{if ($saved) then 'disk_gew.gif' else 'disk.gif'}" class="{if ($saved) then 'stored' else ''}"/>
                </a>
            </td>
            <td class="list-type" style="vertical-align:middle;text-align: center;">
                <svg width="25" height="25">
                    <rect x="1" y="1" width="23" height="23" style="stroke: #006600; fill: rgba(000, 000, 000, 0);"/>
                    <text x="12" y="15" style="fill: #660000;font-size:9px;" text-anchor="middle">{$type}</text>
                </svg>
            </td>
            <td class="list-image">
                <svg xmlns="http://www.w3.org/2000/svg" width="{$svg-hra-framework:THUMB_SIZE_FOR_LIST_VIEW}" height="{$svg-hra-framework:THUMB_SIZE_FOR_LIST_VIEW}" viewBox="0 0 {$svg-viewBox[3]} {$svg-viewBox[4]}">
                    {$entry}
                </svg>
            </td>
            <td class="pagination-toggle" style="vertical-align:middle">
                <a>
                    {$test}
                </a>
            </td>
        </tr>

(:    let $svg-viewbox-width := $:)

    let $highlight := function($string as xs:string) { <span class="highlight">{$string}</span> }
    let $regex := session:get-attribute('tamboti:query')
    let $result := 
        if ($regex)
        then tamboti-common:highlight-matches($result, $regex, $highlight)
        else $result

    return
        $result
};

declare function svg-hra-framework:format-detail-view($entry as node(), $currentPos as xs:int) {
    let $uuid := $entry/@xml:id/string()
    let $svg-viewBox := 
        if (exists($entry/@viewBox)) then
            tokenize($entry/@viewBox/string(), " ")
        else
            (0, 0, $entry/@width/string(), $entry/@height/string())

    
    let $document-uri := document-uri(root($entry))
    let $record-collection := functx:substring-before-last($document-uri, "/")
    let $filename := functx:substring-after-last($document-uri, "/")
    
    let $location-node := 
        <tr>
            <td class="collection-label">Record Location</td>
            <td>
                <div class="collection">
                    {$record-collection}
                </div>
                <div id="file-location-folder" style="display: none;">{$record-collection}</div>
            </td>
        </tr>

    let $record-format-node := 
        <tr>
            <td class="collection-label">Record Format</td>
            <td>
                <div id="record-format" style="display:none;">{$svg-hra-framework:record-type}</div>
                <div>{$svg-hra-framework:record-type}</div>
            </td>
        </tr>
        
    let $title-node := 
        <tr>
            <td class="collection-label" style="font-weight:bold">Title</td>
            <td style="font-weight:bold">{$filename}</td>
        </tr>

    let $stable-link-href := replace(request:get-url(), '/retrieve', '/index.html') || '?search-field=ID&amp;value=' || svg-hra-framework:get-UUID($entry)
    let $stable-link-node :=
            <tr>
                <td class="collection-label">Stable link to this record</td>
                <td>
                    <a href="{$stable-link-href}" target="_blank">{$stable-link-href}</a>
                </td>
            </tr>
    
    (: get annotations :)
(:    let $log := util:log("INFO", "uuid: " || $uuid):)

    let $annotations := map{
        "is-body" := hra-rdf-framework:is-subject($uuid, "xml"),
        "is-target" := hra-rdf-framework:is-object($uuid, "xml")
    }

    let $annotations-node :=
        if ( count($annotations("is-body")) + count($annotations("is-target")) > 0) then
            <tr>
                <td colspan="2" style="text-align:center;">
                    <h3>Annotations</h3>
                </td>
                {
                    for $target in $annotations("is-target")
                        let $bodyIRI := $target/oa:hasBody/@rdf:resource/string()
(:                        let $log := util:log("INFO", $bodyIRI):)
                        let $parsedIRI := hra-rdf-framework:parse-iri($bodyIRI, "xml")
                        let $resolvedIRI := hra-rdf-framework:resolve-tamboti-iri($bodyIRI)
                        
                        let $motivation := $target/oa:motivatedBy/@rdf:resource/string()
                        let $collection-name := util:collection-name(root($resolvedIRI))
                        let $resource-name :=  util:document-name(root($resolvedIRI))
                        let $anno-uuid := functx:substring-after-last($target/@rdf:about/string(), "/")
                        let $resource-can-edit := security:user-has-access(security:get-user-credential-from-session()[1], $collection-name || "/" || $resource-name, ".w.")
                        let $motivation-label := map:get($svg-hra-framework:motivations, $motivation)
                        return
                            <tr>
                                <td class="collection-label">has body</td>
                                <td>
                                    <div>is <span class="annotation motivation">{$motivation-label}</span> for:</div>
                                    <div>
                                        {
                                            (:ToDo: move handling of different xml formats to a abstract top level framework module :)
                                            switch(namespace-uri($resolvedIRI))
                                                case "http://www.vraweb.org/vracore4.htm" return
                                                    switch(name($resolvedIRI))
                                                        case "image" return
    (:                                                        let $log := util:log("INFO", $parsedIRI/*):)
    (:                                                        return:)
                                                             <div class="img-container" onmouseenter="$(this).find('.img-actions-overlay').fadeIn(200);" onmouseleave="$(this).find('.img-actions-overlay').fadeOut(200);" style="max-width:128px; max-height:128px;width:128px;height:128px;">
                                                                    <a href="?search-field=ID&amp;value={$parsedIRI/hra-rdf-framework:resource/string()}">
                                                                        {vra-hra-framework:create-thumbnail-span($parsedIRI/hra-rdf-framework:resource/string(), false(), 128, 128)}
                                                                    </a>
                                                                    {
                                                                        
                                                                        if($config:canvas-editor-path and $resource-can-edit and $motivation = "http://www.shared-canvas.org/ns/painting") then
                                                                            let $parameters := "openBinaryMethod=tamboti&amp;openSVGMethod=tamboti&amp;binary=" || $parsedIRI/hra-rdf-framework:resource/string() || "&amp;svg="|| $uuid || "&amp;tambotiCollection=" || encode-for-uri($record-collection) || "&amp;annotationUUID=" || $anno-uuid
                                                                            return
                                                                                <span class="img-actions-overlay">
                                                                                    <a href="{$config:canvas-editor-path}?{$parameters}" target="_blank">
                                                                                        <img src="resources/images/page_edit.png" style="width:16px;height:16px;cursor:pointer" title="edit canvas" alt="edit canvas"/>
                                                                                    </a>
                                                                                </span>
                                                                        else
                                                                            ()
                                                                    }
                                                                </div>
    (:                                                            vra-hra-framework:create-thumbnail-span($parsedIRI/resource/string(), false(), 128, 128):)
                                                        case "work" return
                                                            "WORK"
                                                        default return
                                                            name($resolvedIRI)
                                                default return
                                                    "test"
                                        }
                                    </div>
                                </td>
                            </tr>
                    }
                {
                    for $body in $annotations("is-body")
                    return
                        <tr>
                            <td class="collection-label">has target</td>
                            <td>
                                <div>motivation: <span class="annotation motivation">{$body/oa:motivatedBy/@rdf:resource/string()}</span> for:</div>
                                <div>
                                    <span class="annotation subject">{$body/oa:hasTarget/@rdf:resource/string()}</span>
                                </div>
                            </td>
                        </tr>
                }
            </tr>
        else
            ""

(:    let $filename := functx:substring-after-last($record-location, "/"):)
    let $result :=
        <table xmlns="http://www.w3.org/1999/xhtml">
            <tr class="pagination-item detail">
                <td>
                    <input class="search-list-item-checkbox" type="checkbox" data-tamboti-record-id="{$entry/svg:svg/@xml:id}"/>
                </td>
                <td class="actions-cell"></td>
                <td style="vertical-align:top;text-align:center;">
                    <div id="image-cover-box">
                        <svg xmlns="http://www.w3.org/2000/svg" width="{$svg-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW}px" height="{$svg-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW}px" viewBox="0 0 {$svg-viewBox[3]} {$svg-viewBox[4]}">
                            {$entry}
                        </svg>
                    </div>
                </td>            
                <td class="detail-xml" style="vertical-align:top;">
                    {svg-hra-framework:toolbar($entry)}
                    <span class="record">
                        <table class="biblio-full">
                            {$location-node}
                            {$record-format-node}
                            {$title-node}
                            {$annotations-node}
                            {$stable-link-node}
                        </table>
                    </span>
                </td>
            </tr>
        </table>
    return 
        $result
};

declare function svg-hra-framework:move-resource($resource-fullpath as xs:anyURI, $target-collection as xs:anyURI) as element(status) {
    let $resource-filename := functx:substring-after-last($resource-fullpath, "/")
    let $source-collection := functx:substring-before-last($resource-fullpath, "/")
    let $destination-path := $target-collection || "/" || $resource-filename
    let $move-record :=
        try {
            (
                xmldb:move($source-collection, $target-collection, $resource-filename),
                (: clear ACL and copy ACL and POSIX-rights from parent collection :)
                sm:clear-acl(xs:anyURI($target-collection || "/" || $resource-filename))
                ,
                security:duplicate-acl($target-collection, $target-collection || "/" || $resource-filename)
                ,
                security:copy-owner-and-group(xs:anyURI($target-collection), xs:anyURI($target-collection || "/" || $resource-filename))
                ,
                <status moved="{$resource-filename}" from="{$source-collection}" to="{$target-collection}" />
            )
        } catch * {
            util:log("DEBUG", "Moving resource failed: Code: " || $err:code || "Descr.: " || $err:description || " Value: " || $err:value )
            ,
            <status id="error">Error trying to move</status>
        }
        
    return
        $move-record
};

declare function svg-hra-framework:remove-resource($document-uri as xs:anyURI) {
    let $resource := functx:substring-after-last($document-uri, "/")
    let $collection-uri := functx:substring-before-last($document-uri, "/")
(:    let $useless := util:log("DEBUG", "Remove resource: " || $document-uri ):)

    return
(:        true():)
(:    let $useless := util:log("DEBUG", "Moving resource failed: Code: " || $err:code || "Descr.: " || $err:description || " Value: " || $err:value ):)
        xmldb:remove($collection-uri, $resource)
};


(:~
: The <b>svg-hra-framework:remove-relations</b> function removes entries from other resources where the submitted uuid is linked.
: @param $uuid uuid of an svg record
: @return true() if successed. Otherwise false()
:)

declare function svg-hra-framework:remove-relations($uuid as xs:anyURI) {
    (: ToDo   :)
    ()
};