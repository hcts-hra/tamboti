xquery version "3.1";

module namespace tei-hra-framework = "http://hra.uni-heidelberg.de/ns/tei-hra-framework";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "../../modules/search/security.xqm";

import module namespace clean = "http://exist-db.org/xquery/mods/cleanup" at "../../modules/search/cleanup.xql";

import module namespace tamboti-common = "http://exist-db.org/tamboti/common" at "../../modules/tamboti-common.xql";
import module namespace tei-common = "http://exist-db.org/tei/common" at "../../modules/tei-common.xql";
import module namespace mods-common = "http://exist-db.org/mods/common" at "../../modules/mods-common.xql";

import module namespace functx="http://www.functx.com";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mods = "http://www.loc.gov/mods/v3";

declare variable $tei-hra-framework:THUMB_SIZE_FOR_GRID := 64;
declare variable $tei-hra-framework:THUMB_SIZE_FOR_GALLERY := 128;
declare variable $tei-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW := 256;
declare variable $tei-hra-framework:THUMB_SIZE_FOR_LIST_VIEW := 128;

(:The $retrieve-tei:primary-roles values are lower-cased when compared.:)
declare variable $tei-hra-framework:primary-roles := ('aut', 'author', 'cre', 'creator', 'composer', 'cmp', 'artist', 'art', 'director', 'drt');

declare function tei-hra-framework:get-UUID($item as element()) {
    $item/@xml:id
};

declare function tei-hra-framework:toolbar($entry as node()) {
(:    let $useless := util:log("DEBUG", "isWritable:" || $isWritable):)
    let $collection := util:collection-name(root($entry))
    let $isWriteable := security:can-write-collection($collection)

    let $id := tei-hra-framework:get-UUID($entry)
    return
        <div class="actions-toolbar">
            <a target="_new" href="source.xql?id={$id}">
                <img title="View XML Source of Record" src="resources/images/script_code.png"/>
            </a>
            {
                (: if the item's collection is writable, display edit/delete and move buttons :)
                if ($isWriteable) then
                    (
                        <form id="edit-tei-record-form" method="post" action="{$config:web-path-to-tei-editor-api}/{$id}" target="_blank">
                            <a onclick="document.getElementById('edit-tei-record-form').submit();">
                                <img title="Edit TEI Record" src="resources/images/page_edit.png"/>
                            </a>
                        </form>                       
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


declare function tei-hra-framework:get-icon-from-folder($size as xs:int, $collection as xs:string) {
    let $thumb := xmldb:get-child-resources($collection)[1]
    let $imgLink := concat(substring-after($collection, "/db"), "/", $thumb)
    return
        <img src="images/{$imgLink}?s={$size}"/>
};

(:~
    Get the preview icon for a linked image resource or get the thumbnail showing the resource type.
:)
declare function tei-hra-framework:get-icon($size as xs:int, $item, $currentPos as xs:int) {
    let $image-url :=
    (: NB: Refine criteria for existence of image:)
        ( 
            $item/mods:location/mods:url[@access="preview"]/string(), 
            $item/mods:location/mods:url[@displayLabel="Path to Folder"]/string() 
        )[1]
    let $type := $item/mods:typeOfResource[1]/string()
    let $hint := 
        if ($type)
        then functx:capitalize-first($type)
        else
            if (in-scope-prefixes($item) = 'xml')
            then 'Unknown Type'
            else 'Extracted Text'
    return
        if (string-length($image-url)) 
        (: Only run if there actually is a URL:)
        (: NB: It should be checked if the URL leads to an image described in the record:)
        then
            let $image-path := concat(util:collection-name($item), "/", $image-url)
            return
                if (collection($image-path)) 
                then tei-hra-framework:get-icon-from-folder($size, $image-path)
                else
                    let $imgLink := concat(substring-after(util:collection-name($item), "/db"), "/", $image-url)
                    return
                        <img title="{$hint}" src="images/{$imgLink}?s={$size}"/>        
        else
        (: For non-image records:)
            let $type := 
                (: If there is a typeOfResource, render the icon for it. :)
                if ($type)
                (: Remove spaces and commas from the image name:)
                then translate(translate($type,' ','_'),',','')
                else
                    (: If there is no typeOfResource, but the resource is XML, render the default icon for it. :)
                    if (in-scope-prefixes($item) = 'xml')
                    then 'shape_square'
                    (: Otherwise it is non-XML contents extracted from a document by tika. This could be a PDF, a Word document, etc. :) 
                    else 'text-x-changelog'
            return 
                <img title="{$hint}" src="resources/images/{$type}.png"/>
};


declare function tei-hra-framework:list-view-table($item as node(), $currentPos as xs:int) {
    let $document-uri  := document-uri(root($item))
    let $node-id := util:node-id($item)
    let $id := concat($document-uri, '#', $node-id)
    let $id := functx:substring-after-last($id, '/')
    let $id := functx:substring-before-last($id, '.')
    let $type := substring($id, 1, 1)
    let $stored := session:get-attribute("personal-list")
    let $saved := exists($stored//*[@id = $id])
    return
        <tr xmlns="http://www.w3.org/1999/xhtml" class="pagination-item list">
            <td><input class="search-list-item-checkbox" type="checkbox" data-tamboti-record-id="{document-uri(root($item))}"/></td>        
            <td class="pagination-number">{$currentPos}</td>
            {
            <td class="actions-cell">
                <a id="save_{$id}" href="#{$currentPos}" class="save">
                    <img title="{if ($saved) then 'Remove Record from My List' else 'Save Record to My List'}" src="resources/images/{if ($saved) then 'disk_gew.gif' else 'disk.gif'}" class="{if ($saved) then 'stored' else ''}"/>
                </a>
            </td>
            }
            <td class="list-type icon magnify">
            { tei-hra-framework:get-icon($tei-hra-framework:THUMB_SIZE_FOR_GALLERY, $item, $currentPos)}
            </td>
            <td/>
            {
            <td class="pagination-toggle">
                <!--Zotero does not import tei records <abbr title="{bs:get-item-uri(concat($item, $id-position))}"></abbr>-->
                <a>
                {
                    let $collection := util:collection-name($item)
                    let $collection := functx:replace-first($collection, '/db/', '')
                    (:let $clean := clean:cleanup($item):)
                    return
                        try {
                            tei-hra-framework:format-list-view(string($currentPos), $item, $collection, $document-uri, $node-id)
                        } catch * {
                            util:log("DEBUG", "Code: " || $err:code || "Descr.: " || $err:description || " Value: " || $err:value ),
                            <td class="error" colspan="2">
                                {$config:error-message-before-link} 
                                <a href="{$config:error-message-href}{$item/@xml:id/string()}.">{$config:error-message-link-text}</a>
                                {$config:error-message-after-link}
                                <p>Caught error {$err:code}: {$err:description}. {("(line ", $err:line-number, ", column ", $err:column-number, ")")}</p>
                            </td>
                        }
                }
                </a>
            </td>
            }
        </tr>
};


 
(:~
: The <b>tei-hra-framework:format-detail-view</b> function returns the detail view of a VRA record.
: @param $position the position of the record displayed with the search results (this parameter is not used).
: @param $entry
: @param $collection-short the location of the TEI record, with '/db/' removed.
: @param $document-uri 
: @param $node-id 
: @return an XHTML table element.
:)
declare function tei-hra-framework:format-detail-view($position as xs:string, $entry as element(), $collection-short as xs:string, $document-uri as xs:string, $node-id as xs:string) as element(table) {
    let $matumi-link := concat('/exist/apps/matumi/entry.html?doc=', $document-uri, '&amp;node=', $node-id, '#', $node-id)
        (:let $log := util:log("DEBUG", ("##$matumi-link): ", $matumi-link)):)
    let $result :=
    <table xmlns="http://www.w3.org/1999/xhtml" class="biblio-full">
    {
    let $collection := replace(replace($collection-short, '^' || $config:mods-commons || '/', $config:content-root),'^' || $config:users-collection || '/', $config:content-root)
    (:let $log := util:log("DEBUG", ("##$collection): ", $collection)):)
    return
    <tr>
        <td class="collection-label">Record Location</td>
        <td>
            <div id="file-location-folder" style="display: none;">{xmldb:decode-uri($collection-short)}</div>
            <div class="collection">{$collection}</div>
        </td>
    </tr>
    ,
    let $format := 'TEI Record'
    return
        <tr>
            <td class="collection-label">Record Format</td>
            <td>
                <div id="record-format" style="display:none;">TEI</div>
                <div>
                    {$format}
                </div>
            </td>
        </tr>
    ,
    let $title := doc($document-uri)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1]
    let $entry := 
        if ($entry instance of element(tei:TEI) or $entry instance of element(tei:head) or $entry instance of element(tei:div)) 
        then <p>The document is too large to be retrieved. Please access the document in <a href="{$matumi-link}" target="_blank">Matumi</a> or make a search targeting a specific field in Tamboti.</p> 
    else $entry
    (:let $log := util:log("DEBUG", ("##$entry): ", $entry)):)
    return
        <tr>
            <td class="collection-label">Title</td>
            <td>{$title/string()}</td>
        </tr>
        ,
        <tr>
            <td class="collection-label">Text</td>
            <td>
                <span>{tei-common:render($entry, <parameters xmlns=""><destination>detail-view</destination></parameters>)}</span>
                </td>
        </tr>
        ,
        <tr>
            <td class="collection-label">Link to Whole Text in</td>
            <td>
                <span><a href="{$matumi-link}" target="_blank">Matumi</a></span>
                </td>
        </tr>
        
    }
    </table>
    let $highlight := function($string as xs:string) { <span class="highlight">{$string}</span> }
    let $result := tamboti-common:highlight-matches($result, session:get-attribute('tamboti:query'), $highlight)
    let $result := mods-common:clean-up-punctuation($result)
    return
        $result
};

(:~
: The <b>tei-hra-framework:format-list-view</b> function returns the list view of a sequence of TEI records.
: @param $entry a TEI record or a fragment of a TEI record.
: @param $collection-short the location of the TEI record, with '/db/' removed
: @param $position the position of the record displayed with the search results (this parameter is not used)
: @param $node-id the node id of the record.
: @return an XHTML span.
:)
declare function tei-hra-framework:format-list-view($position as xs:string, $entry as element(), $collection-short as xs:string, $document-uri as xs:string, $node-id as xs:string) as element(span) {
    let $title := doc($document-uri)/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[1]
    let $entry := 
        if ($entry instance of element(tei:TEI)) 
        then () 
        else $entry
    let $result :=
    <div>
	    <span>{$title/string()}</span>
	    <span>{tei-common:render($entry, <parameters xmlns=""><destination>detail-view</destination></parameters>)}</span>
    </div>
    let $highlight := function($string as xs:string) { <span class="highlight">{$string}</span> }
    let $result := tamboti-common:highlight-matches($result, session:get-attribute('tamboti:query'), $highlight)
    let $result := mods-common:clean-up-punctuation($result)
    return
        $result
};



declare function tei-hra-framework:detail-view-table($item as element(), $currentPos as xs:int) {
    let $isWritable := security:can-write-collection(util:collection-name($item))
    let $document-uri  := document-uri(root($item))
    let $node-id := util:node-id($item)
    let $id := concat(document-uri(root($item)), '#', util:node-id($item))
    let $id := functx:substring-after-last($id, '/')
    let $id := functx:substring-before-last($id, '.')
    let $type := substring($id, 1, 1)
    let $stored := session:get-attribute("personal-list")
    let $saved := exists($stored//*[@id = $id])

    return
        <tr class="pagination-item detail" xmlns="http://www.w3.org/1999/xhtml">
            <td><input class="search-list-item-checkbox" type="checkbox" data-tamboti-record-id="{$item/@id}"/></td>
            <td class="pagination-number">{$currentPos}</td>
            <td class="actions-cell">
                <a id="save_{$id}" href="#{$currentPos}" class="save">
                    <img title="{if ($saved) then 'Remove Record from My List' else 'Save Record to My List'}" src="resources/images/{if ($saved) then 'disk_gew.gif' else 'disk.gif'}" class="{if ($saved) then 'stored' else ''}"/>
                </a>
            </td>
            <td class="detail-xml">
                { tei-hra-framework:toolbar($item) }
                <!--NB: why is this phoney HTML tag used to anchor the Zotero unIPA?-->
                <!--Zotero does not import tei records <abbr title="{bs:get-item-uri(concat($item, $id-position))}"></abbr>-->
                {
                    let $collection := util:collection-name($item)
                    let $collection := functx:replace-first($collection, '/db/', '')
                    let $clean := clean:cleanup($item)
                    return
                        try {
                            tei-hra-framework:format-detail-view(string($currentPos), $clean, $collection, $document-uri, $node-id)
                        } catch * {
                        <td class="error" colspan="2">
                        {$config:error-message-before-link} 
                        <a href="{$config:error-message-href}{$item/@xml:id/string()}.">{$config:error-message-link-text}</a>
                        {$config:error-message-after-link}
                        </td>
                        }
                }
            </td>
        </tr>
};

declare function tei-hra-framework:move-resource($resource-fullpath as xs:anyURI, $target-collection as xs:anyURI) as element(status) {
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