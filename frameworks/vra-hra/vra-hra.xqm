xquery version "3.0";

module namespace vra-hra-framework = "http://hra.uni-heidelberg.de/ns/vra-hra-framework";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "../../modules/search/security.xqm";

import module namespace tamboti-utils = "http://hra.uni-heidelberg.de/ns/tamboti/utils" at "../../modules/utils/utils.xqm";
import module namespace clean = "http://exist-db.org/xquery/mods/cleanup" at "../../modules/search/cleanup.xql";
import module namespace mods-common = "http://exist-db.org/mods/common" at "../../modules/mods-common.xql";
import module namespace tamboti-common = "http://exist-db.org/tamboti/common" at "../../modules/tamboti-common.xql";
(:import module namespace image-link-generator = "http://hra.uni-heidelberg.de/ns/tamboti/modules/display/image-link-generator" at "../../modules/display/image-link-generator.xqm";:)

import module namespace functx="http://www.functx.com";

declare namespace vra = "http://www.vraweb.org/vracore4.htm";

(:The $vra-hra-framework:primary-roles values are lower-cased when compared.:)
declare variable $vra-hra-framework:primary-roles := ('aut', 'author', 'cre', 'creator', 'composer', 'cmp', 'artist', 'art', 'director', 'drt');

declare variable $vra-hra-framework:loading-image := $config:app-http-root || "/themes/default/images/ajax-loader.gif";

declare variable $vra-hra-framework:THUMB_SIZE_FOR_GRID := 64;
declare variable $vra-hra-framework:THUMB_SIZE_FOR_GALLERY := 128;
declare variable $vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW := 256;
declare variable $vra-hra-framework:THUMB_SIZE_FOR_LIST_VIEW := 128;

declare function vra-hra-framework:get-UUID($item as element()) {
    if (exists($item/vra:work)) then
        $item/vra:work/@id
    else 
        ()
};

declare function vra-hra-framework:toolbar($item as element(), $isWritable as xs:boolean) {
(:    let $useless := util:log("DEBUG", "isWritable:" || $isWritable):)
    let $collection := util:collection-name($item)

    (:determine for image record:)
    let $id := vra-hra-framework:get-UUID($item)

    let $imageId :=  
        (: relids/refid workaround :)
        if (exists($item/vra:work)) then
            let $rel :=
                if (exists($item/vra:work/vra:relationSet/vra:relation/@pref[.='true'])) then 
                    $item/vra:work/vra:relationSet/vra:relation[@pref='true']
                else 
                    $item/vra:work/vra:relationSet/vra:relation[1]
            return
                if(starts-with(data($rel/@refid), "i_")) then
                    data($rel/@refid)
                else 
                    data($rel/@relids)
        else $item/vra:image/@id

    let $workdir := 
        if (contains($collection, 'VRA_images')) then
            functx:substring-before-last($collection, "/")
        else $collection
    let $workdir := 
        if (ends-with($workdir,'/')) then
            $workdir 
        else 
            $workdir || '/'
    
    let $imagepath := $workdir || 'VRA_images/' || $imageId || ".xml"
    
    return
        <div class="actions-toolbar">
            <a target="_new" href="source.xql?id={$id}&amp;clean=yes">
                <img title="View XML Source of Record" src="theme/images/script_code.png"/>
            </a>
            {
                (: if the item's collection is writable, display edit/delete and move buttons :)
                if ($isWritable) then
                    (
                        (: ToDo: define editor for VRA in config.xqm instead of hard-coding Ziziphus here:)
                        if (xmldb:collection-available("/db/apps/ziziphus/")) then
                            <a target="_new" href="/exist/apps/ziziphus/record.xql?id={$id}&amp;workdir={$workdir}&amp;imagepath={$imagepath}">
                                <img title="Edit VRA Record" src="theme/images/page_edit.png"/>
                            </a>
                        else 
                            ()
                        ,
                        <a class="remove-resource" href="#{$id}"><img title="Delete Record" src="theme/images/delete.png"/></a>
                        ,
                        <a class="move-resource" href="#{$id}"><img title="Move Record" src="theme/images/shape_move_front.png"/></a>
                        ,
                        if (not($item/vra:image/@id)) then
                            <a class="upload-file-style" directory="false" href="#{$id}" onclick="updateAttachmentDialog">
                                <img title="Upload Attachment" src="theme/images/database_add.png" />
                            </a>
                        else ()
                    )
                else
                    ()
            }
        </div>
};

(:~
: The <b>vra-hra-framework:format-detail-view</b> function returns the detail view of a VRA record.
: @param $entry a VRA record, processed by clean:cleanup() in session.xql.
: @param $collection-short the location of the VRA record, with '/db/' removed.
: @param $position the position of the record displayed with the search results (this parameter is not used).
: @return an XHTML table.
:)
declare function vra-hra-framework:format-detail-view($position as xs:string, $entry as element(vra:vra), $collection-short as xs:string, $type as xs:string, $id as xs:string) as element(table) {
    let $main-title := $entry//vra:titleSet/vra:title[1]/text()
    
    let $record-location-node :=
        <tr>
            <td class="collection-label">Record Location</td>
            <td>
                <div class="collection">
                    {replace(replace(xmldb:decode-uri($collection-short), '^' || $config:mods-commons || '/', $config:mods-root || '/'),'^' || $config:users-collection || '/', $config:mods-root || '/')}
                </div>
                <div id="file-location-folder" style="display: none;">{xmldb:decode-uri($collection-short)}</div>
            </td>
        </tr>
    
    let $record-format-node := 
        let $record-type :=
            switch ($type)
                case "i" return
                    "VRA Image Record"
                case "w" return
                    "VRA Work Record"
                default return
                    "VRA Collection Record"
        return
            <tr>
                <td class="collection-label">Record Format</td>
                <td>
                    <div id="record-format" style="display:none;">VRA</div>
                    <div>{$record-type}</div>
                </td>
            </tr>

    (: titles :)
    let $title-node :=
        for $title in $entry//vra:titleSet/vra:title
            return
                <tr>
                    <td class="collection-label" style="font-weight:bold">Title</td>
                    <td style="font-weight:bold">{$title/text()}</td>
                </tr>
    (: agents :)
    let $agent-node :=
        for $agent in $entry//vra:agentSet/vra:agent
            let $name := $agent/vra:name
            let $role := $agent/vra:role
            let $role := mods-common:get-role-term-label-for-detail-view($role)
            let $role := 
                if ($role) then 
                    $role
                else 
                    'Agent'
            return
                <tr>
                    <td class="collection-label">{$role}</td>
                    <td>{$name/text()}</td>
                </tr>
    (: date :)
    let $date-node :=
        for $date in $entry//vra:dateSet/vra:date
            return
                let $date-type := functx:capitalize-first($date/@type) 
                let $earliestDate := $date/vra:earliestDate
                let $earliestDate := 
                    if (contains($earliestDate, 'T')) then
                        functx:substring-before-last-match($earliestDate, 'T')
                    else 
                        $earliestDate
                let $earliestDate := 
                    if ($date/vra:earliestDate[@circa eq 'true']) then 
                        "ca. " || $earliestDate
                    else 
                        $earliestDate
                (:let $log := util:log("DEBUG", ("##$earliestDate2): ", $earliestDate)):)
                
                let $latestDate := $date/vra:latestDate
                let $latestDate := 
                    if (contains($latestDate, 'T')) then 
                        functx:substring-before-last-match($latestDate, 'T')
                    else 
                        $latestDate
                let $latestDate := 
                    if ($date/vra:latestDate[@circa eq 'true']) then 
                        "ca. " || $latestDate
                    else 
                        $latestDate
                        
                let $date :=
                    if ($earliestDate eq $latestDate) then
                        $earliestDate
                    else 
                        if ($earliestDate and $latestDate) then
                            $earliestDate || ' - ' || $latestDate
                        else 
                            ($earliestDate, $latestDate)
                (:let $log := util:log("DEBUG", ("##$date): ", $date)):)
                (:let $log := util:log("DEBUG", ("##$date-type): ", $date-type)):)
                return 
                    <tr>
                        <td class="collection-label">{$date-type}</td>
                        <td>{$date}</td>
                    </tr>
    (: location :)
    let $location-node :=
        for $location in $entry//vra:locationSet/vra:location
            return
                <tr>
                    <td class="collection-label">{functx:capitalize-first($location/@type/string())}</td>
                    <td>{$location/vra:name}</td>
                </tr>
    (: description :)
    let $description-node :=
        for $description in $entry//vra:descriptionSet/vra:description[not(vra:text)]
            return
                <tr>
                    <td class="collection-label">Description</td>
                    <td>{$description}</td>
                </tr>
    (: description with text and author :)
    (: NB: do author :)
    let $description-with-details-node :=
        for $description in $entry//vra:descriptionSet/vra:description[vra:text]
            return
                <tr>
                    <td class="collection-label">Description</td>
                    <td>{$description/vra:text}</td>
                </tr>
    (: relation :)
    let $relation-node :=
        for $relation in $entry//vra:relationSet/vra:relation[@type="imageIs"]
            let $type := $relation/@type
            let $relids := data($relation/@relids)
            let $type-label := 
                switch ($type)
                    case 'imageIs' return
                        'Image Record'
                    case 'imageOf' return
                        'Work Record'
                    default return
                        'Collection Record'
            (: Elevate rights because user is not able to search whole $config:mods-root   :)
            (: ToDo: do not search whole $config:mods-root, since we know the image-record is in VRA_images/ relative to work record  :)
            let $list-view := 
                system:as-user($config:dba-credentials[1], $config:dba-credentials[2], 
                    collection($config:mods-root)//vra:image[@id = $relids]/..
                )
            let $list-view := vra-hra-framework:format-list-view('', $list-view, '')
            return
                <tr>
                    <td class="collection-label">{$type-label}</td>
                    <td>{$list-view}</td>
                </tr>
    (: relation-href :)
    let $relation-href-node :=
        let $href-relation := $entry//vra:relationSet/vra:relation[@type="relatedTo"]
        for $rel in $href-relation
            return
               <tr>
                   <td class="collection-label">
                      <a href="?search-field=ID&amp;value={$rel/@href}&amp;query-tabs=advanced-search-form&amp;default-operator=and">{concat('&lt;&lt; ', $rel/@type)}</a>
                   </td>
                   <td>Tamboti MODS Record</td>
               </tr>

    (: subjects :)
    let $subjects-node :=
        if ($entry//vra:subjectSet/vra:subject) then
            <tr>
                <td class="collection-label">Subjects</td>
                <td>
                    {
                        string-join(
                            for $subject in $entry//vra:subjectSet/vra:subject
                                return
                                    $subject,
                            ', ')
                }</td>
            </tr>
        else ()
        
    (: inscription :)
    let $inscription-node :=
        for $inscription in $entry//vra:inscriptionSet/vra:inscription
            return
                <tr>
                    <td class="collection-label">Inscription</td>
                    <td>{$inscription}</td>
                </tr>
                
    (: material :)
    let $material-node :=
        for $material in $entry//vra:materialSet/vra:material
            return
                <tr>
                    <td class="collection-label">Material</td>
                    <td>{$material}</td>
                </tr>

    (: technique :)
    let $technique-node :=
        for $technique in $entry//vra:techniqueSet/vra:technique
            return
                <tr>
                    <td class="collection-label">Technique</td>
                    <td>{$technique}</td>
                </tr>

   (: measurements :)
    let $measurement-node :=
        let $measurements := $entry//vra:measurementsSet/vra:measurements
        return
            if (not(empty($measurements))) then
                <tr>
                    <td class="collection-label">Measuremenets</td>
                    <td>
                    {
                        for $measurement in $measurements
                            let $type := $measurement/@type/string()
                            let $unit := $measurement/@unit/string()
                            let $value := $measurement/text()
                            let $display := functx:capitalize-first($type) || ":" || $value || " " || $unit
                            return 
                                <div>{$display}</div>
                    }
                    </td>
                </tr>
            else
                ()
                
    (: stable link:)
    let $stable-link-href := replace(request:get-url(), '/retrieve', '/index.html') || '?search-field=ID&amp;value=' || $entry/vra:work/@id
    let $stable-link-node :=
            <tr>
                <td class="collection-label">Stable link to this record</td>
                <td>
                    <a href="{$stable-link-href}" target="_blank">{$stable-link-href}</a>
                </td>
            </tr>

    let $title := $entry//vra:titleSet/vra:title[1]/text()
    let $image-id := $entry//vra:relationSet/vra:relation[1]/@relids/string()
    let $image-href := $config:app-http-root || "/modules/display/image.xql?uuid=" || $image-id || "&amp;width=" || $vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW || "&amp;height=" || $vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW

    let $image-alt := xmldb:encode-uri($title)
    let $image-embed := "<figure>&#10;&#9;<img src=&quot;" || $image-href || "&quot; alt=&quot;" || $image-alt || "&quot;/>&#10;&#9;<figcaption>" || xmldb:encode-uri($title) || "</figcaption>&#10;</figure>"
    
    let $image-embedding-node := 
            <tr>
                <td class="collection-label">Code to embed image</td>
                <td>
                    <textarea readonly="readonly" style="padding:5px;font-size:8px;background-color: #FFFFFF; width:95%; height: 8em;" onclick="$(this).select();">{$image-embed}</textarea>
                </td>
            </tr>

    (: CONSTRUCT THE COMPLETE RESULT-DISPLAY   :)
    let $result :=
        <table xmlns="http://www.w3.org/1999/xhtml" class="biblio-full">
            {$record-location-node}
            {$record-format-node}
            {$title-node}
            {$agent-node}
            {$date-node}
            {$location-node}
            {$description-node}
            {$description-with-details-node}
            {$relation-node}
            {$relation-href-node}
            {$subjects-node}
            {$inscription-node}
            {$material-node}
            {$technique-node}
            {$measurement-node}
            {$stable-link-node}
            {$image-embedding-node}
        </table>

    let $result := <span xmlns="http://www.w3.org/1999/xhtml" class="record">{$result}</span>
    let $highlight := function($string as xs:string) { <span class="highlight">{$string}</span> }
    let $regex := session:get-attribute('regex')
    let $result := 
        if ($regex) 
        then tamboti-common:highlight-matches($result, $regex, $highlight) 
        else $result
    let $result := mods-common:clean-up-punctuation($result)
    return
        $result
};

(:~
: The <b>vra-hra-framework:format-list-view</b> function returns the list view of a sequence of VRA records.
: @param $entry a VRA record, processed by clean:cleanup().
: @param $collection-short the location of the VRA record, with '/db/' removed
: @param $position the position of the record displayed with the search results (this parameter is not used)
: @param $type the type of the record, 'c', 'w', 'i', for colleciton, work, image.
: @param $id the id of the record.
: @return an XHTML span.
:)
declare function vra-hra-framework:format-list-view($position as xs:string, $entry as element(), $collection-short as xs:string) as element(span) {
    let $agents-ignore := ( 'col', 'digitizing', 'Metadata contact' )
    let $agents-node :=
        <div>
            {
                let $agents := $entry//vra:agentSet/vra:agent
                let $agents := 
                    for $agent in $agents[not(vra:role = $agents-ignore)]
                        let $name := $agent/vra:name
                        let $role := mods-common:get-role-term-label-for-detail-view($agent/vra:role)
                            return
                                (
                                    <span class="vra-agent">{$name}<span class="vra-role"> ({$role});</span></span>
                                )
                return $agents
            }   
        </div>

    let $title-node :=
        <div>
            <span class="vra-title">{$entry//vra:titleSet/vra:title/text()}</span>
        </div>
    
    let $date-node :=
        <div>
            {
                let $earliestDate := $entry//vra:dateSet/vra:date[@type eq 'creation']/vra:earliestDate/text()
                let $earliestDate := 
                    if (contains($earliestDate, 'T')) then 
                        functx:substring-before-last-match($earliestDate, 'T')
                    else 
                        $earliestDate
                let $earliestDate := 
                    if ($entry//vra:dateSet/vra:date[@type eq 'creation']/vra:earliestDate[@circa eq 'true']) then 
                        concat('ca. ', $earliestDate)
                    else 
                        $earliestDate
                (:let $log := util:log("DEBUG", ("##$earliestDate1): ", $earliestDate)):)
                
                let $latestDate := $entry//vra:dateSet/vra:date[@type = 'creation']/vra:latestDate/text()
                let $latestDate := 
                    if (contains($latestDate, 'T')) then 
                        functx:substring-before-last-match($latestDate, 'T')
                    else 
                        $latestDate
                let $latestDate := 
                    if ($entry//vra:dateSet/vra:date[@type eq 'creation']/vra:latestDate[@circa = 'true']) then 
                        concat('ca. ', $latestDate)
                    else 
                        $latestDate
                let $date :=
                    if ($earliestDate = $latestDate) then 
                        $earliestDate
                    else 
                        if ($earliestDate and $latestDate) then
                            concat($earliestDate, ' - ', $latestDate)
                        else 
                            ($earliestDate, $latestDate)
                (:let $log := util:log("DEBUG", ("##$date): ", $date)):)
                return
                    if(not(empty($date))) then
                        <span class="vra-date">
                            {
                                if (contains($date, 'T')) then
                                    functx:substring-before-last-match($date, 'T')
            (:                        functx:substring-before-last-match($date, 'T'):)
                                else
                                    $date
                            }
                        </span>
                    else 
                        ()

            }
        </div>
        
    let $location-node := 
        if (not(empty($entry//vra:locationSet/vra:location))) then
            <div><span class="vra-location">Repositories: </span>
                {
                    for $location in $entry//vra:locationSet/vra:location
                        return
                            
                            switch(data($location/@type))
                                case "repository" return
                                    (
                                        <span class="vra-location">{string-join($location/vra:name/string(), ", ")}; </span>
                                    )
                                default return
                                    ()  
                }
            </div>
        else
            ()

    
    let $result :=
        <div class="vra-record">
            {$title-node}
            {$agents-node}
            {$date-node}
            {$location-node}
          </div>
    
    let $highlight := function($string as xs:string) {
        <span class="highlight">{$string}</span> 
    }
    
    let $regex := session:get-attribute('regex')
    let $result := 
        if ($regex) then
            tamboti-common:highlight-matches($result, $regex, $highlight) 
        else 
            $result
    let $result := mods-common:clean-up-punctuation($result)
    return
        $result    
};


declare function vra-hra-framework:detail-view-table($item as element(vra:vra), $currentPos as xs:int) {
    let $isWritable := security:can-write-collection(util:collection-name($item))
    let $document-uri := document-uri(root($item))
    let $id := concat($document-uri, '#', util:node-id($item))
    let $id := functx:substring-after-last($id, '/')
    let $id := functx:substring-before-last($id, '.')

    (: ToDo: look for parent node instead of substringing the uuid :)
    let $type := substring($id, 1, 1)
    let $id-position :=
        if ($type eq 'c')
        then '/vra:collection/@id'
        else 
            if ($type eq 'w')
            then '/vra:work/@id'
            else '/vra:image/@id'

    let $stored := session:get-attribute("personal-list")
    let $saved := exists($stored//*[@id = $id])
    return
        <tr class="pagination-item detail" xmlns="http://www.w3.org/1999/xhtml">
            <td><input class="search-list-item-checkbox" type="checkbox" data-tamboti-record-id="{$item/vra:work/@id}"/></td>
            <td class="pagination-number">{$currentPos}</td>
            <td class="actions-cell">
                <a id="save_{$id}" href="#{$currentPos}" class="save">
                    <img title="{if ($saved) then 'Remove Record from My List' else 'Save Record to My List'}" src="theme/images/{if ($saved) then 'disk_gew.gif' else 'disk.gif'}" class="{if ($saved) then 'stored' else ''}"/>
                </a>
            </td>
            <td class="detail-type" style="vertical-align:top"><img src="theme/images/image.png" title="Still Image"/></td>
            <td style="vertical-align:top;">
                <div id="image-cover-box"> 
                { 
                   (: relids/refid workaround :)
                    for $rel in $item//vra:relationSet/vra:relation[@type = "imageIs"]
                        let $image-uuid := 
                            if(starts-with(data($rel/@relids), "i_")) then
                                data($rel/@relids)
                            else 
                                if(starts-with(data($rel/@refid), "i_")) then
                                    data($rel/@refid)
                                else
                                    ()
                        let $image := security:get-resource($image-uuid)
                        return
                            <p>{vra-hra-framework:return-thumbnail-detail-view($image)}</p>
                }
                </div>
            </td>            
            <td class="detail-xml" style="vertical-align:top;">
                { vra-hra-framework:toolbar($item, $isWritable) }
                <!--Zotero does not import vra records <abbr class="unapi-id" title="{bs:get-item-uri(concat($item, $id-position))}"></abbr>-->
                {
                    let $collection := util:collection-name($item)
                    let $collection := functx:replace-first($collection, '/db/', '')
                    let $clean := clean:cleanup($item)
                    return
                        try {
                            vra-hra-framework:format-detail-view(string($currentPos), $clean, $collection, $type, $id)
                        } catch * {
                            util:log("DEBUG", "Code: " || $err:code || "Descr.: " || $err:description || " Value: " || $err:value ),
                            <td class="error" colspan="2">
                                {$config:error-message-before-link} 
                                <a href="{$confgi:error-message-href}{$item/*/@id/string()}.">{$config:error-message-link-text}</a>
                                {$config:error-message-after-link}
                            </td>
                        }                        
                }
            </td>
        </tr>
};

declare function vra-hra-framework:list-view-table($item as node(), $currentPos as xs:int) {
    let $id := concat(document-uri(root($item)), '#', util:node-id($item))
    let $id := functx:substring-after-last($id, '/')
    let $id := functx:substring-before-last($id, '.')
    let $type := substring($id, 1, 1)
    let $id-position :=
        if ($type eq 'c')
        then '/vra:collection/@id'
        else 
            if ($type eq 'w')
            then '/vra:work/@id'
            else '/vra:image/@id'
    let $stored := session:get-attribute("personal-list")
    let $saved := exists($stored//*[@id eq $id])
        return
            <tr xmlns="http://www.w3.org/1999/xhtml" class="pagination-item list">
                <td><input class="search-list-item-checkbox" type="checkbox" data-tamboti-record-id="{$item/vra:work/@id}"/></td>
                <td class="pagination-number" style="vertical-align:middle">{$currentPos}</td>
                {
                <td class="actions-cell" style="vertical-align:middle">
                    <a id="save_{$id}" href="#{$currentPos}" class="save">
                        <img title="{if ($saved) then 'Remove Record from My List' else 'Save Record to My List'}" src="theme/images/{if ($saved) then 'disk_gew.gif' else 'disk.gif'}" class="{if ($saved) then 'stored' else ''}"/>
                    </a>
                </td>
                }
                <td class="list-type" style="vertical-align:middle"><img src="theme/images/image.png" title="Still Image"/></td>
                { 
                    (: relids/refid workaround :)
                    let $relations := 
                        if (exists($item//vra:relation[@type="imageIs" and @pref="true"])) then 
                            $item//vra:relation[@type="imageIs" and @pref="true"]
                        else
                            $item//vra:relation[@type="imageIs"]
                    let $relids :=
                        for $rel in $relations
                            let $image-uuid := 
                                if(starts-with(data($rel/@refid), "i_")) then
                                    data($rel/@refid)
                                    else 
                                        data($rel/@relids)
                                return $image-uuid 
                    (:NB: relids can hold multiple values; the image record with @pref on vra:relation is "true".
                    For now, we disregard this; otherwise we have to check after retrieving the image records.:)
                    let $relids := tokenize($relids, ' ')

                    (: Elevate rights because user is not able to search whole $config:mods-root   :)
                    (: ToDo: do not search whole $config:mods-root, since we know the image-record is in VRA_images/ relative to work record  :)
                    let $image := 
                        system:as-user($config:dba-credentials[1], $config:dba-credentials[2], 
                            collection($config:mods-root)//vra:image[@id = $relids]
                        )

                    return
                        <td class="list-image">{vra-hra-framework:return-thumbnail-list-view($image)}</td>               
                }
                {
                <td class="pagination-toggle" style="vertical-align:middle">
                    <!--Zotero does not import vra records <abbr class="unapi-id" title="{bs:get-item-uri(concat($item, $id-position))}"></abbr>-->
                    <a>
                    {
                        let $collection := util:collection-name($item)
                        let $collection := functx:replace-first($collection, '/db/', '')
                        let $clean := clean:cleanup($item)
                        return
                            try {
                                vra-hra-framework:format-list-view(string($currentPos), $clean, $collection)
                            } catch * {
                                util:log("DEBUG", "Code: " || $err:code || "Descr.: " || $err:description || " Value: " || $err:value ),
                                <td class="error" colspan="2">
                                    {$config:error-message-before-link} 
                                    <a href="{$config:error-message-href}{$item/*/@id/string()}.">{$config:error-message-link-text}</a>
                                    {$config:error-message-after-link}
                                </td>
                            }
                    }
                    </a>
                </td>
                }
            </tr>
};


(:declare function vra-hra-framework:return-thumbnail-detail-view($image){:)
(:    let $image-uuid := $image/@id:)
(:    let $image-thumbnail-href := image-link-generator:generate-href($image-uuid, "tamboti-thumbnail"):)
(:    let $image-size1000-href := image-link-generator:generate-href($image-uuid, "tamboti-size1000"):)
(:    let $image-size150-href := image-link-generator:generate-href($image-uuid, "tamboti-size150")    :)
(:    let $image-url := :)
(:        if (security:get-user-credential-from-session()[1] eq "guest") then:)
(:            <img src="{$image-thumbnail-href}" alt="image" class="relatedImage picture"/>:)
(:        else :)
(:            <a href="{$image-size1000-href}" target="_blank">:)
(:                <img src="{$image-size150-href}" alt="image" class="relatedImage picture zoom"/>:)
(:            </a>:)
(::)
(:    return $image-url:)
(:};:)
(::)
(:declare function vra-hra-framework:return-thumbnail-list-view($image){:)
(:    let $image-uuid := $image/@id:)
(:    let $image-thumbnail-href := image-link-generator:generate-href($image-uuid, "tamboti-thumbnail"):)
(:    let $image-size1000-href := image-link-generator:generate-href($image-uuid, "tamboti-size1000"):)
(:    let $image-url := :)
(:        if (security:get-user-credential-from-session()[1] eq "guest") then:)
(:            <img src="{$image-thumbnail-href}" alt="image" class="relatedImage picture"/>:)
(:        else :)
(:            <a href="{$image-size1000-href}" target="_blank">:)
(:                <img src="{$image-thumbnail-href}" alt="image" class="relatedImage picture zoom"/>:)
(:            </a>:)
(::)
(:    return $image-url:)
(:};:)



declare function vra-hra-framework:return-thumbnail-detail-view($image){
    let $image-uuid := $image/@id
    let $image-url := 
        if (security:get-user-credential-from-session()[1] eq "guest") then
            <span style="width:{$vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW}px;min-height:{$vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW}px;">
                <img src="{$vra-hra-framework:loading-image}" class="placeholder"/>
<img src="{$config:app-http-root}/modules/display/image.xql?uuid={$image-uuid}&amp;width={$vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW}&amp;height={$vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW}" alt="image" class="relatedImage picture" style="max-width:{$vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW}px;max-height:{$vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW}px;display:none;" onload="$(this).parent().find('.placeholder').hide();$(this).show();"/>
            </span>
        else 
            <span style="width:{$vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW}px;min-height:{$vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW}px;">
                <a href="{$config:app-http-root}/components/iipmooviewer/mooviewer.xq?uuid={$image-uuid}" target="_blank">
                    <img src="{$config:app-http-root}/modules/display/image.xql?uuid={$image-uuid}&amp;width={$vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW}&amp;height={$vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW}" alt="image" class="relatedImage picture zoom" style="max-width:{$vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW}px;max-height:{$vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW}px;display:none;" onload="$(this).parent().find('.placeholder').hide();$(this).show();"/> 
                </a>
            </span>
    return $image-url
};

declare function vra-hra-framework:return-thumbnail-list-view($image){
    let $image-uuid := $image/@id
    let $image-url := 
        if (security:get-user-credential-from-session()[1] eq "guest") then
            <span style="width:{$vra-hra-framework:THUMB_SIZE_FOR_LIST_VIEW}px;min-height:{$vra-hra-framework:THUMB_SIZE_FOR_LIST_VIEW}px;">
                <img src="{$vra-hra-framework:loading-image}" class="placeholder"/>
                <img src="{$config:app-http-root}/modules/display/image.xql?schema=IIIF&amp;call=/{$image-uuid}/full/!{$vra-hra-framework:THUMB_SIZE_FOR_LIST_VIEW},{$vra-hra-framework:THUMB_SIZE_FOR_LIST_VIEW}/0/default.jpg" alt="image" class="relatedImage picture" style="max-width:{$vra-hra-framework:THUMB_SIZE_FOR_LIST_VIEW}px;max-height:{$vra-hra-framework:THUMB_SIZE_FOR_LIST_VIEW}px;display:none;" onload="$(this).parent().find('.placeholder').hide();$(this).show();"/>
            </span>
        else 
            <span style="width:{$vra-hra-framework:THUMB_SIZE_FOR_LIST_VIEW}px;min-height:{$vra-hra-framework:THUMB_SIZE_FOR_LIST_VIEW}px;">
                <a href="{$config:app-http-root}/components/iipmooviewer/mooviewer.xq?uuid={$image-uuid}" target="_blank">
                    <img src="{$vra-hra-framework:loading-image}" class="placeholder" />
                    <img src="{$config:app-http-root}/modules/display/image.xql?schema=IIIF&amp;call=/{$image-uuid}/full/!{$vra-hra-framework:THUMB_SIZE_FOR_LIST_VIEW},{$vra-hra-framework:THUMB_SIZE_FOR_LIST_VIEW}/0/default.jpg" alt="image" class="relatedImage picture" style="max-width:{$vra-hra-framework:THUMB_SIZE_FOR_LIST_VIEW}px;max-height:{$vra-hra-framework:THUMB_SIZE_FOR_LIST_VIEW}px;display:none;" onload="$(this).parent().find('.placeholder').hide();$(this).show();"/>
                </a>
            </span>

    return $image-url
};

declare function vra-hra-framework:get-vra-work-record-list($work-record as element()) as xs:string+ {
    (
            base-uri($work-record),
            vra-hra-framework:get-vra-image-records-list($work-record)
    )
};

declare function vra-hra-framework:get-vra-image-records-list($work-record as element()) as xs:string+ {
    let $image-record-ids := $work-record//vra:relationSet/vra:relation[@type eq "imageIs"]/@relids/string()
    let $image-record-ids := tokenize($image-record-ids, ' ')
    return
        for $image-record-id in $image-record-ids
        let $image-record := collection($config:mods-root-minus-temp)/vra:vra[vra:image/@id eq $image-record-id]
        let $image-record-url := base-uri($image-record)
        let $image-url := resolve-uri($image-record/*/@href, $image-record-url)        
        return
            (
                base-uri($image-record),
                $image-url
            )
};

declare function vra-hra-framework:move-resource($source-collection as xs:anyURI, $target-collection as xs:anyURI, $resource-id as xs:string) as element(status) {
    let $result :=
        system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
            (
                try {
                    let $resource-name := util:document-name(collection($source-collection)//vra:work[@id = $resource-id][1])
                    let $log := util:log("DEBUG", "resName:" || $resource-name)
                    (: create VRA_images collection, if needed :)
                    let $create-VRA-image-collection := tamboti-utils:create-vra-image-collection($target-collection)
                    let $relations := collection($source-collection)//vra:work[@id = $resource-id][1]/vra:relationSet//vra:relation[@type="imageIs"]
                    let $vra-images-target-collection := $target-collection || "/VRA_images"

                    (: move each image record :)
                    let $move-images := 
                        for $relation in $relations
                            let $image-uuid := data($relation/@relids)
                            let $image-vra := collection($source-collection)//vra:image[@id = $image-uuid]
                            let $image-resource-name := util:document-name($image-vra)
                            let $binary-name := data($image-vra/@href)
                            let $vra-images-source-collection := util:collection-name($image-vra)
                            return
                                (
                                    (: if binary available, move it as well :)
                                    if(util:binary-doc-available($vra-images-source-collection || "/" || $binary-name)) then
                                        security:move-resource-to-tamboti-collection($vra-images-source-collection, $binary-name, $vra-images-target-collection)
                                    else
                                        util:log("DEBUG", "not available: " || $vra-images-source-collection || "/" || $binary-name)
                                    ,
                                    (: move image record :)
                                    security:move-resource-to-tamboti-collection($vra-images-source-collection, $image-resource-name, $vra-images-target-collection)
                                )
                    let $useless := util:log("ERROR", "Error: move resource failed: " ||  $err:code || ": " || $err:description)
                    let $move-work-record := security:move-resource-to-tamboti-collection($source-collection, $resource-name, $target-collection)
                    return
                        $resource-name
                } catch * {
                    util:log("DEBUG", "Error: move resource failed: " ||  $err:code || ": " || $err:description),
                    false()
                }
            )
        )

    return
        if($result) then
            <status moved="{$resource-id}" from="{$source-collection}" to="{$target-collection}">{$target-collection}</status>
        else
            <status id="error">Error trying to move</status>
};

declare function vra-hra-framework:remove-resource($document-uri as xs:anyURI){
    let $vra-work := doc($document-uri)
    let $collection-name := util:collection-name(root($vra-work))
    let $doc-name := util:document-name(root($vra-work))

    let $resource-id := vra-hra-framework:get-UUID($vra-work//vra:vra)
    let $vra-images := collection($config:mods-root-minus-temp)//vra:vra[vra:image/vra:relationSet/vra:relation[contains(@relids, $resource-id)]]
    (:NB: we assume that all image files are in the same collection as their metadata and that all image records belonging to a work record are in the same collection:)
    let $vra-image-collection := util:collection-name($vra-images[1])
    let $vra-binary-names := $vra-images/vra:image/@href/string()   
    return
        if (count($vra-binary-names) gt 0) then
            try {
                (: Remove the binaries :)
                for $vra-binary-name in $vra-binary-names
                    return
                        (:NB: since this iterates inside another iteration, files are attempted deleted which have been deleted already, causing the script to halt. However,:)
                        (:the existence of the file to be deleted should first be checked, in order to prevent the function from halting in case the file does not exist.:)
                        if (util:binary-doc-available($vra-image-collection || '/' || $vra-binary-name)) then
                            xmldb:remove($vra-image-collection, $vra-binary-name)
                        else 
                            let $useless := util:log("INFO", "VRA-Binary not found (maybe external image service?): "|| $vra-binary-name)
                            return
                                ()
                ,
                (: remove the image records:)
                for $image-record in $vra-images
                    return
                        xmldb:remove($vra-image-collection, util:document-name($image-record))
                ,
                (: remove the work record:)
                xmldb:remove($collection-name, $doc-name)
                ,
                true()
            } catch * {
                let $log := util:log("DEBUG", "Error: remove resource failed: " ||  $err:code || ": " || $err:description)
                return false()
            }
        else
            let $useless := util:log("DEBUG", "counting VRA-Binaries eq 0")
            return
                true()
};
