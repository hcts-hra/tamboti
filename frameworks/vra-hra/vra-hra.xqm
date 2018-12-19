xquery version "3.1";

module namespace vra-hra-framework = "http://hra.uni-heidelberg.de/ns/vra-hra-framework";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "../../modules/search/security.xqm";

import module namespace tamboti-utils = "http://hra.uni-heidelberg.de/ns/tamboti/utils" at "../../modules/utils/utils.xqm";
import module namespace clean = "http://exist-db.org/xquery/mods/cleanup" at "../../modules/search/cleanup.xql";
import module namespace mods-common = "http://exist-db.org/mods/common" at "../../modules/mods-common.xql";
import module namespace tamboti-common = "http://exist-db.org/tamboti/common" at "../../modules/tamboti-common.xql";

import module namespace hra-rdf-framework = "http://hra.uni-heidelberg.de/ns/hra-rdf-framework" at "../hra-rdf/hra-rdf-framework.xqm";

import module namespace functx="http://www.functx.com";

declare namespace vra = "http://www.vraweb.org/vracore4.htm";
(:declare namespace svg="http://www.w3.org/2000/svg";:)
declare namespace oa="http://www.w3.org/ns/oa#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare variable $vra-hra-framework:ERROR := xs:QName("vra-hra-framework:error");

(:The $vra-hra-framework:primary-roles values are lower-cased when compared.:)
declare variable $vra-hra-framework:primary-roles := ('aut', 'author', 'cre', 'creator', 'composer', 'cmp', 'artist', 'art', 'director', 'drt');

declare variable $vra-hra-framework:loading-image := $config:app-http-root || "/themes/default/images/ajax-loader.gif";

declare variable $vra-hra-framework:THUMB_SIZE_FOR_GRID := 64;
declare variable $vra-hra-framework:THUMB_SIZE_FOR_GALLERY := 128;
declare variable $vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW := 256;
declare variable $vra-hra-framework:THUMB_SIZE_FOR_LIST_VIEW := 128;

declare variable $vra-hra-framework:motivations := map{
    "http://www.shared-canvas.org/ns/painting" := "canvas"
};


declare function vra-hra-framework:get-UUID($item as element()) {
    if (exists($item/vra:work)) then
        $item/vra:work/@id
    else 
        ()
};

(:declare function vra-hra-framework:get-annotations($work as element(vra:work)) {:)
(:    let $relatedItems := :)
(:    let $work-uuid := replace(/@xlink:href/string(), '^#*', ''):)
(:    let $work := collection($naddara-config:resource-root)//vra:work[@id=$work-uuid]:)
(:    let $image-uuid := $work/vra:relationSet/vra:relation[@type="imageIs"][1]/@relids/string():)
(:    let $image-record := collection($naddara-config:resource-root)//vra:image[@id=$image-uuid]:)
(::)
(:};:)

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
    let $allRelations := $entry//vra:relationSet/vra:relation
(:    let $additionalRelations := $allRelations[not(@pref="true")]:)
    
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
    
    (: relations :)
    let $relation-node :=
        for $relation in $allRelations
            let $type := $relation/@type
            let $relids := data($relation/@relids)
(:            let $log := util:log("INFO", "relids: " || $relids):)
(:            let $log := util:log("INFO", "type: " || $type):)
(:            let $log := util:log("INFO", $relation):)
            let $annotations := 
                if($relids) then
                    vra-hra-framework:_create-annotations-display-node($relids, "/" || xmldb:decode-uri($collection-short))
                else
                    ()
            let $type-label := 
                switch ($type)
                    case 'imageIs' return
                        (: display a thubnail view :)
                            vra-hra-framework:create-thumbnail-span($relids, true(), 100, 100)
                        
                    case 'imageOf' return
                        'Work Record'
                        
                    case 'relatedTo' return
                        <a href="?search-field=ID&amp;value={$relation/@href}&amp;query-tabs=advanced-search-form&amp;default-operator=and">{'&lt;&lt;' || $type}</a>
                        
                    default return
                        $type
            
            let $display := $relation/string()
(:            let $display := :)
(:                switch ($type):)
(:                    case 'relatedTo' return:)
(:                        'Related To ' || $relation/string():)
(:                    default return:)
(:                        $relation/string():)

            (: get annotations for vra:image records :)
            
            (: Elevate rights because user is not able to search whole $config:mods-root   :)
            (: ToDo: do not search whole $config:mods-root, since we know the image-record is in VRA_images/ relative to work record  :)
(:            let $vra-image := :)
(:                system:as-user($config:dba-credentials[1], $config:dba-credentials[2], :)
(:                    collection($config:mods-root)//vra:image[@id = $relids]:)
(:                ):)
(:(:            let $list-view := vra-hra-framework:format-list-view('', $list-view, ''):):)
(:            let $log := util:log("INFO", $relation):)
            return
                <tr>
                    <td class="collection-label">{$type-label}</td>
                    <td>
                        <div style="font-weight:bold">{$display}</div>
                        <div>
                            {$annotations}
                        </div>
                    </td>
                </tr>
                
    let $rights-node :=
        let $rights := $entry//vra:rightsSet/vra:rights
        for $right in $rights
            let $type := $right/@type/string()
            let $holder := 
                if($right/vra:rightsHolder/string() = "") then
                    ""
                else
                    " (by " || $right/vra:rightsHolder/string() || ")"
            return
               <tr>
                   <td class="collection-label">{$type}</td>
                   <td>{$right/vra:text/string()}<br/>
                        {$holder}</td>
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
    let $image-href :=  request:get-scheme() || "://" || request:get-server-name() || ":" || request:get-server-port() || $config:app-http-root || "/iiif/" || $image-id || "/full/!" || $vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW || "," || $vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW || "/0/default.jpg"

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
            {$subjects-node}
            {$inscription-node}
            {$material-node}
            {$technique-node}
            {$measurement-node}
            {$rights-node}
            {
                if(count($allRelations) > 0) then
                    <tr>
                        <td colspan="2" style="text-align:center;"><h3>Related Items</h3></td>
                    </tr>
                else
                    ()
            }
            {$relation-node}
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

declare function vra-hra-framework:get-vra-image-uuid($rel as element(vra:relation)) {
    if (starts-with(data($rel/@relids), "i_"))
    then data($rel/@relids)
    else 
        if (starts-with(data($rel/@refid), "i_"))
        then data($rel/@refid)
        else ()
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
    
    let $allRelations := $item//vra:relationSet/vra:relation
    
    return
        <tr class="pagination-item detail" xmlns="http://www.w3.org/1999/xhtml">
            <td><input class="search-list-item-checkbox" type="checkbox" data-tamboti-record-id="{$item/vra:work/@id}"/></td>
            <td class="pagination-number">{$currentPos}</td>
            <td class="actions-cell">
                <a id="save_{$id}" href="#{$currentPos}" class="save">
                    <img title="{if ($saved) then 'Remove Record from My List' else 'Save Record to My List'}" src="theme/images/{if ($saved) then 'disk_gew.gif' else 'disk.gif'}" class="{if ($saved) then 'stored' else ''}"/>
                </a>
            </td>
            <td class="detail-type" style="vertical-align:top">
                <img src="theme/images/image.png" title="Still Image"/>
            </td>
            <td style="vertical-align:top;">
                <div id="image-cover-box"> 
                { 
                    let $main-image-relations := 
                        (: if @pref then take this. If not then take the first one :)
                        if ($item//vra:relationSet/vra:relation[@type="imageIs" and @pref="true"])
                        then $item//vra:relationSet/vra:relation[@type="imageIs" and @pref="true"]
                        else $item//vra:relationSet/vra:relation[@type="imageIs"][1]
                        
                    return
                        if ($main-image-relations)
                        then
                            let $main-image-uuid := vra-hra-framework:get-vra-image-uuid($main-image-relations)
                            
                            return
                                <p>
                                    {
                                        vra-hra-framework:create-thumbnail-span($main-image-uuid, xs:boolean(not(security:get-user-credential-from-session()[1] eq "guest")), $vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW, $vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW)
                                    }
                                </p>
                        else ()
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
                            util:log("INFO", "Code: " || $err:code || "Descr.: " || $err:description || " Value: " || $err:value ),
                            <td class="error" colspan="2">
                                <div style="display:none">Error: {$err:code} Descr.: {$err:description} Value: {$err:value}</div>
                                {$config:error-message-before-link}
                                <a href="{$config:error-message-href}{$item/*/@id/string()}.">{$config:error-message-link-text}</a>
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
                    if (exists($item//vra:relationSet/vra:relation[@type="imageIs" and @pref="true"]))
                    then $item//vra:relationSet/vra:relation[@type="imageIs" and @pref="true"]
                    else $item//vra:relationSet/vra:relation[@type="imageIs"]
    
                return
                    <td class="list-image">
                        {
                            if (exists($relations))
                            then
                                let $relids :=
                                    for $rel in $relations
                                        let $image-uuid := 
                                            if (starts-with(data($rel/@refid), "i_"))
                                            then data($rel/@refid)
                                            else data($rel/@relids)
                                            
                                    return $image-uuid 
                                (:NB: relids can hold multiple values; the image record with @pref on vra:relation is "true".
                                For now, we disregard this; otherwise we have to check after retrieving the image records.:)
                                let $relids := tokenize($relids, ' ')
                
                                (: Elevate rights because user is not able to search whole $config:mods-root   :)
                                (: ToDo: do not search whole $config:mods-root, since we know the image-record is in VRA_images/ relative to work record  :)
                                let $image := collection($config:mods-root)//vra:image[@id = $relids]
                                let $image-uuid := $image/@id                                
                                
                                return vra-hra-framework:create-thumbnail-span($image-uuid, xs:boolean(not(security:get-user-credential-from-session()[1] eq "guest")), $vra-hra-framework:THUMB_SIZE_FOR_LIST_VIEW, $vra-hra-framework:THUMB_SIZE_FOR_LIST_VIEW)
                            else ()
                        }
                    </td>               
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


declare function vra-hra-framework:create-thumbnail-span($image-uuid as xs:string, $zoom as xs:boolean, $width as xs:int, $height as xs:int) {
    let $height :=
        if ($height) then
            $height
        else
            $width
    let $images := (
    <img src="{$vra-hra-framework:loading-image}" class="placeholder" />
    ,
    <img src="/exist/apps/tamboti/iiif/{$image-uuid}/full/!{$width},{$height}/0/default.jpg" alt="image" class="relatedImage picture" style="max-width:{$width}px; max-height:{$height}px; display:none;" onload="$(this).parent().find('.placeholder').hide(); $(this).show();" onerror="$(this).parent().find('.placeholder').hide();"/>
)

    return
        if($zoom) then 
            <span style="width:{$width}px; min-height:{$width}px;">
                <a href="{$config:app-http-root}/components/iipmooviewer/mooviewer.xq?uuid={$image-uuid}" target="_blank">{$images}</a>
            </span>
        else
            <span style="width:{$width}px; min-height:{$width}px;">{$images}</span>

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
        system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
            (
                try {
                    let $resource-name :=  util:document-name(collection($source-collection)//vra:work[@id = $resource-id][1])
                    let $log := util:log("DEBUG", "resName:" || $resource-name)
                    let $vra-images-target-collection := xs:anyURI($target-collection || "/VRA_images")

                    (: create VRA_images collection, if needed :)
                    let $create-VRA-collection :=
                        if (xmldb:collection-available($vra-images-target-collection)) then
                            ()
                        else
                            (
                                util:log("DEBUG", "create: " || $target-collection || "/VRA_images"),
                                xmldb:create-collection($target-collection, "/VRA_images"),
                                sm:chmod($vra-images-target-collection, $config:collection-mode),
                                sm:chgrp($vra-images-target-collection, $config:biblio-users-group),
                                security:duplicate-acl($target-collection, $vra-images-target-collection),
                                sm:chown($vra-images-target-collection, xmldb:get-owner($target-collection))
                            )

(:                    let $create-VRA-image-collection := tamboti-utils:create-vra-image-collection($target-collection):)
                    let $relations := collection($source-collection)//vra:work[@id = $resource-id][1]/vra:relationSet//vra:relation[@type="imageIs"]

                    (: move each image record :)
                    let $move-images := 
                        for $relation in $relations
                            let $image-uuid := data($relation/@relids)
                            let $image-vra := collection($source-collection)//vra:image[@id = $image-uuid]
                            let $image-resource-name := util:document-name(root($image-vra))
                            let $binary-name := data($image-vra/@href)
                            let $vra-images-source-collection := util:collection-name($image-vra)
                            let $move-image := 
                                (
                                    (: if binary available, move it as well :)
                                    if(util:binary-doc-available($vra-images-source-collection || "/" || $binary-name)) then
                                        let $log := util:log("DEBUG", "moveBinary: " || $vra-images-source-collection || "/" || $binary-name || " to " || $vra-images-target-collection)
                                        return
                                            vra-hra-framework:move-xmldb-resource($vra-images-source-collection, xs:anyURI($vra-images-target-collection), $binary-name)
                                    else
                                        util:log("DEBUG", "not available: " || $vra-images-source-collection || "/" || $binary-name)
                                    ,
                                    (: move image record :)
                                        let $log := util:log("DEBUG", "moveImageRecord: " || $vra-images-source-collection || "/" || $image-resource-name || " to " || $vra-images-target-collection)
                                        return
                                            vra-hra-framework:move-xmldb-resource($vra-images-source-collection, $vra-images-target-collection, $image-resource-name)
                                )
                            return 
                                true()
                    let $log := util:log("DEBUG", "moveWorkRecord: " ||  $source-collection || "/" || $resource-name || " to: " || $target-collection)

                    let $move-work-record := vra-hra-framework:move-xmldb-resource($source-collection, $target-collection, $resource-name)
                    return
                        <status moved="{$resource-id}" from="{$source-collection}" to="{$target-collection}">{$target-collection}</status>

                } catch * {
                    let $log := util:log("INFO", "Error: move resource failed: " ||  $err:code || ": " || $err:description)
                    return
                        <status id="error">Error trying to move</status>

                }
            )
        )
};

declare function vra-hra-framework:move-xmldb-resource($source-collection as xs:anyURI, $target-collection as xs:anyURI, $resource-id as xs:string) {
    try {
        let $move-resource :=  xmldb:move($source-collection, $target-collection, $resource-id)
        let $change-permissions :=
            (: if user is owner of target collection first change owner since he will get no ACE and will shut out himself  :)
            if(xmldb:get-owner($target-collection) = security:get-user-credential-from-session()[1]) then
                (
                    security:copy-owner-and-group(xs:anyURI($target-collection), xs:anyURI($target-collection || "/" || $resource-id))
                    ,
                    security:copy-collection-ace-to-resource-apply-modechange($target-collection, xs:anyURI($target-collection || "/" || $resource-id))
                )
            else
                (
                    security:copy-collection-ace-to-resource-apply-modechange($target-collection, xs:anyURI($target-collection || "/" || $resource-id))
                    ,
                    security:copy-owner-and-group(xs:anyURI($target-collection), xs:anyURI($target-collection || "/" || $resource-id))
                )
        return 
            ()
        } catch * {
            error($vra-hra-framework:ERROR, "Error moving resource. " || $err:code || " " || $err:description || " " || $err:value)
        }
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

declare function vra-hra-framework:_create-annotations-display-node($uuid as xs:string, $collection-name as xs:string) {
(:    let $useless := util:log("INFO", "uuid: " || $uuid):)
    let $annotations := map{
        "is-body" := hra-rdf-framework:is-subject($uuid, "xml"),
        "is-target" := hra-rdf-framework:is-object($uuid, "xml")
    }
    let $add-anno-span :=
        if ($config:canvas-editor-path) then
            let $parameters := "openBinaryMethod=tamboti&amp;openSVGMethod=tamboti&amp;binary=" || $uuid || "&amp;tambotiCollection=" || encode-for-uri($collection-name)
            return
                <a href="{$config:canvas-editor-path}?{$parameters}" target="_blank">
                    <img src="theme/images/add.png" style="width:16px;height:16px;cursor:pointer" title="new annotation" alt="new annotation"/>
                </a>
        else 
            ()

    let $annotations-node :=
        <div>
            <div style="font-weight:bold;">Annotations: {$add-anno-span}</div>
    {
        if ( count($annotations("is-body")) + count($annotations("is-target")) > 0) then
            <div>
                {
                    for $target in $annotations("is-target")
                        let $bodyIRI := $target/oa:hasBody/@rdf:resource/string()
                        let $parsedIRI := hra-rdf-framework:parse-iri($bodyIRI, "xml")
                        let $resolvedIRI := hra-rdf-framework:resolve-tamboti-iri($bodyIRI)
                        
                        let $motivation := $target/oa:motivatedBy/@rdf:resource/string()
                        let $collection-name := util:collection-name(root($resolvedIRI))
                        let $resource-name :=  util:document-name(root($resolvedIRI))
    
                        let $resource-can-edit := sm:has-access(xs:anyURI($collection-name || "/" || $resource-name), "w")
                        let $collection-can-create := sm:has-access(xs:anyURI($collection-name), "wx")
(:                        let $log := util:log("INFO", xs:anyURI($collection-name || "/" || $resource-name)):)
                        let $motivation-label := map:get($vra-hra-framework:motivations, $motivation)

                        return
                            <div>
                                <div>has body</div>
                                <div>
                                    <div>has <span class="annotation motivation">{$motivation-label}</span> for:</div>
                                </div>
                            </div>
                }
                {
                    for $body in $annotations("is-body")
(:                        let $useless := util:log("INFO", $body) :)
                    
                        let $motivation := $body/oa:motivatedBy/@rdf:resource/string()
                        let $bodyIRI := $body/oa:hasTarget/@rdf:resource/string()
(:                        let $useless := util:log("INFO", $bodyIRI) :)
                        
                        let $parsedIRI := hra-rdf-framework:parse-iri($bodyIRI, "xml")
                        let $resolvedIRI := hra-rdf-framework:resolve-tamboti-iri($bodyIRI)

                        let $collection-name := util:collection-name(root($resolvedIRI))
                        let $resource-name :=  util:document-name(root($resolvedIRI))

                        let $resource-can-edit := sm:has-access(xs:anyURI($collection-name || "/" || $resource-name), "w")
                        let $collection-can-create := sm:has-access(xs:anyURI($collection-name), "wx")
(:                        let $log := util:log("INFO", xs:anyURI($collection-name || "/" || $resource-name)):)
(:                        let $log := util:log("INFO", "can-edit: " || $resource-can-edit):)

                        let $anno-uuid := functx:substring-after-last($body/@rdf:about/string(), "/")

                        let $motivation-label := map:get($vra-hra-framework:motivations, $motivation)
                    
                        return
                            <div>
                                <div>has target</div>
                                <div>
                                    <div>is <span class="annotation motivation">{$body/oa:motivatedBy/@rdf:resource/string()}</span> for:</div>
                                        {
                                            switch(namespace-uri($resolvedIRI))
                                                case "http://www.w3.org/2000/svg" return
                                                    let $svg-viewBox := 
                                                        if (exists($resolvedIRI/@viewBox)) then
                                                            tokenize($resolvedIRI/@viewBox/string(), " ")
                                                        else
                                                            (0, 0, $resolvedIRI/@width/string(), $resolvedIRI/@height/string())
                                                    return
                                                        <div style="width:128px;height:128px;border:1px solid black;" onmouseenter="$(this).find('.svg-actions-overlay').fadeIn(200);" onmouseleave="$(this).find('.svg-actions-overlay').fadeOut(200);" >
                                                            <div style="width:128px;cursor:pointer">
                                                                <a href="?search-field=ID&amp;value={$parsedIRI/hra-rdf-framework:resource/string()}">
                                                                    <div style="float:left">
                                                                        <svg xmlns="http://www.w3.org/2000/svg" width="128px" height="128px" viewBox="0 0 {$svg-viewBox[3]} {$svg-viewBox[4]}">
                                                                            {$resolvedIRI}
                                                                        </svg>
                                                                    </div>
                                                                </a>
                                                                    {
                                                                        if($config:canvas-editor-path and $resource-can-edit and $motivation = "http://www.shared-canvas.org/ns/painting") then
                                                                            let $parameters := "openBinaryMethod=tamboti&amp;openSVGMethod=tamboti&amp;binary=" || $uuid || "&amp;svg="|| $parsedIRI/hra-rdf-framework:resource/string() || "&amp;tambotiCollection=" || encode-for-uri($collection-name) || "&amp;annotationUUID=" || $anno-uuid
                                                                            return
                                                                                <div class="svg-actions-overlay" style="width:128px;">
                                                                                    <a href="{$config:canvas-editor-path}?{$parameters}" target="_blank">
                                                                                        <img src="theme/images/page_edit.png" style="width:16px;height:16px;cursor:pointer" title="edit canvas" alt="edit canvas"/>
                                                                                    </a>
                                                                                </div>
                                                                            else
                                                                                ()
                                                                    }
                                                            </div>
                                                        </div>
                                                default return
                                                    <span class="annotation subject">{$body/oa:hasTarget/@rdf:resource/string()}</span>
                                        }
                                </div>
                            </div>
                }
            </div>
        else
            ""
        }
    </div>
            
    return $annotations-node
};
