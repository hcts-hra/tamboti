xquery version "3.1";

module namespace wiki-hra-framework = "http://hra.uni-heidelberg.de/ns/wiki-hra-framework";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "../../modules/search/security.xqm";

import module namespace tamboti-common = "http://exist-db.org/tamboti/common" at "../../modules/tamboti-common.xql";
import module namespace mods-common = "http://exist-db.org/mods/common" at "../../modules/mods-common.xql";
import module namespace vra-hra-framework = "http://hra.uni-heidelberg.de/ns/vra-hra-framework" at "/db/apps/tamboti/frameworks/vra-hra/vra-hra.xqm";

import module namespace functx = "http://www.functx.com";

declare namespace atom = "http://www.w3.org/2005/Atom";
(:declare namespace html = "http://www.w3.org/1999/xhtml";:)
declare namespace vra = "http://www.vraweb.org/vracore4.htm";(:delete when finished:)
declare namespace wiki = "http://exist-db.org/xquery/wiki";
declare namespace mods = "http://www.loc.gov/mods/v3";

declare function wiki-hra-framework:get-icon-from-folder($size as xs:int, $collection as xs:string) {
    let $thumb := xmldb:get-child-resources($collection)[1]
    let $imgLink := concat(substring-after($collection, "/db"), "/", $thumb)
    return
        <img src="images/{$imgLink}?s={$size}"/>
};

(:~
    Get the preview icon for a linked image resource or get the thumbnail showing the resource type.
:)
declare function wiki-hra-framework:get-icon($size as xs:int, $item, $currentPos as xs:int) {
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
                then wiki-hra-framework:get-icon-from-folder($size, $image-path)
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


declare function wiki-hra-framework:list-view-table($item as node(), $currentPos as xs:int) {
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
            <td><input class="search-list-item-checkbox" type="checkbox" data-tamboti-record-id="{$item/@id}"/></td>
            <td class="pagination-number">{$currentPos}</td>
            {
            <td class="actions-cell">
                <a id="save_{$id}" href="#{$currentPos}" class="save">
                    <img title="{if ($saved) then 'Remove Record from My List' else 'Save Record to My List'}" src="resources/images/{if ($saved) then 'disk_gew.gif' else 'disk.gif'}" class="{if ($saved) then 'stored' else ''}"/>
                </a>
            </td>
            }
            <td class="list-type icon magnify">
            { wiki-hra-framework:get-icon($vra-hra-framework:THUMB_SIZE_FOR_GALLERY, $item, $currentPos)}
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
                            wiki-hra-framework:format-list-view(string($currentPos), $item, $collection, $document-uri, $node-id)
                        } catch * {
                            util:log("DEBUG", "Code: " || $err:code || "Descr.: " || $err:description || " Value: " || $err:value ),
                            <td class="error" colspan="2">
                                {$config:error-message-before-link} 
                                <a href="{$config:error-message-href}{$item/@xml:id/string()}.">{$config:error-message-link-text}</a>
                                {$config:error-message-after-link}
                            </td>
                        }
                }
                </a>
            </td>
            }
        </tr>
};


(:~
: The <b>wiki-hra-framework:format-detail-view</b> function returns the detail view of a VRA record.
: @param $entry a VRA record, processed by clean:cleanup() in session.xql.
: @param $collection the location of the VRA record, with '/db/' removed.
: @param $position the position of the record displayed with the search results (this parameter is not used).
: @return an XHTML table.
:)
declare function wiki-hra-framework:format-detail-view($position as xs:string, $entry as element(), $collection as xs:string, $type as xs:string, $id as xs:string) as element(table) {
    (:let $log := util:log("DEBUG", ("##$entry11): ", $entry)):)
    let $result :=
    <table xmlns="http://www.w3.org/1999/xhtml" class="biblio-full">
    {
    <tr>
        <td class="collection-label">Record Location</td>
        <td><div class="collection">{replace(replace(xmldb:decode($collection), '^' || $config:mods-commons || '/', $config:content-root),'^' || $config:users-collection || '/', $config:content-root)}</div></td>
    </tr>
    ,
        <tr>
            <td class="collection-label">Record Format</td>
            <td>Wiki Record</td>
        </tr>
    ,
    let $current-feed-path := concat($collection, "/", 'feed.atom')
    let $current-feed := doc($current-feed-path)
    let $current-feed := 
        if ($current-feed) 
        then $current-feed 
            else doc(concat(functx:substring-before-last-match($collection, '/'), "/", 'feed.atom'))
    return
        <tr>
            <td class="collection-label">Current Feed Title</td>
            <td>{$current-feed//atom:title}</td>
        </tr>
    ,
    let $child-resources := xmldb:get-child-resources($collection)
    for $child-resource in $child-resources
    where ends-with($child-resource, '.atom') and $child-resource ne concat($collection, '.feed.atom')
    return
    let $feed := doc(concat($collection, "/", $child-resource))
    let $feed-title := $feed//atom:title
    let $feed-subtitle := $feed//atom:subtitle
    let $feed-id := $feed//atom:id
    let $url := concat(replace(request:get-url(), '/retrieve', '/index.html'), '?search-field=ID&amp;value=', $feed-id)
    return
        if ($feed-title eq $entry//atom:title)
        then ()
        else
        <tr>
            <td class="collection-label">Sibling Feed Title</td>
            <td><a href="{$url}">{concat($feed-title, if ($feed-subtitle) then concat(': ', $feed-subtitle) else ())}</a></td>
        </tr>
    ,
    let $upper-feed-paths := wiki:make-paths-above-collection($collection, '/', '/Wiki/')
    for $feed-path in $upper-feed-paths[. ne $collection]
        let $feed-path := concat($feed-path, '/feed.atom')
        let $log := util:log("DEBUG", ("##$feed-path): ", $feed-path))
        let $feed := doc($feed-path)
        let $feed-title := $feed//atom:title
        let $feed-subtitle := $feed//atom:subtitle
        let $feed-id := $feed//atom:id/string()
        let $log := util:log("DEBUG", ("##$feed-id): ", $feed-id))
        let $url := concat(replace(request:get-url(), '/retrieve', '/index.html'), '?search-field=ID&amp;value=', $feed-id)
        let $log := util:log("DEBUG", ("##$url): ", $url))
            return
                if ($feed-title eq $entry//atom:title)
                then ()
                else
                    <tr>
                        <td class="collection-label">Upper Feed Titles</td>
                        <td><a href="{$url}">{concat($feed-title, if ($feed-subtitle) then concat(': ', $feed-subtitle) else ())}</a></td>
                    </tr>
    ,
    (: titles :)
    
            <tr>
                <td class="collection-label">Title</td>
                <td>{$entry//atom:title}</td>
            </tr>
    ,
    (: agents :)
            <tr>
                <td class="collection-label">Author</td>
                <td>{$entry//atom:name}</td>
            </tr>
    ,
    (: date :)
                <tr>
                    <td class="collection-label">Published</td>
                    <td>{$entry//atom:published}</td>
                </tr>
                ,
                <tr>
                    <td class="collection-label">Last Updated</td>
                    <td>{$entry//atom:updated[last()]}</td>
                </tr>
    ,
    (: contents :)
    let $atom-content-src := $entry//atom:content/@src/string()
    let $contents-path := concat($collection, "/", $atom-content-src)
    let $contents := util:parse-html(doc($contents-path))
        return
            <tr>
                <td class="collection-label">Contents</td>
                <td>{$contents}</td>
            </tr>
    ,
    (: description :)
    for $description in $entry//vra:descriptionSet/vra:description[not(vra:text)]
        return
            <tr>
                <td class="collection-label">Description</td>
                <td>{$description}</td>
            </tr>
    ,
    (: description with text and author :)
    (: NB: do author :)
    for $description in $entry//vra:descriptionSet/vra:description[vra:text]
        return
            <tr>
                <td class="collection-label">Description</td>
                <td>{$description/vra:text}</td>
            </tr>
    ,
    (: relation :)
    (:
    let $relations := $entry//vra:relationSet/vra:relation
    for $relation in $relations
        let $type := $relation/@type
        let $type := functx:capitalize-first(functx:camel-case-to-words($type, ' '))
        let $relids := $relation/@relids
        let $relids := tokenize($relids, ' ')
        for $relid at $i in $relids
            let $type := substring($relid, 1, 1)
            let $type := 
                if ($type eq 'i')
                then 'Image Record'
                else
                    if ($type eq 'w')
                    then 'Work Record'
                    else 'Collection Record'
            let $list-view := collection($config:content-root)//vra:image[@id = $relid]/..
            let $list-view := wiki-hra-framework:format-list-view('', $list-view, '')
            return
                <tr>
                    <td class="collection-label">{$type}</td>
                    <td>{$list-view}</td>
                </tr>
    ,
    :)
    (: subjects :)
    
    (:for $subject in $entry//vra:subjectSet/vra:subject
        return
            <tr>
                <td class="collection-label">Subject</td><td>{$subject}</td>
            </tr>
    :)
    
    if ($entry//vra:subjectSet/vra:subject)
    then
        <tr>
            <td class="collection-label">Subjects</td>
            <td>{
            string-join(for $subject in $entry//vra:subjectSet/vra:subject
            return
            $subject, ', ')
            }</td>
        </tr>
    else ()
    ,
    (: inscription :)
    for $inscription in $entry//vra:inscriptionSet/vra:inscription
        return
            <tr>
                <td class="collection-label">Inscription</td><td>{$inscription}</td>
            </tr>
    ,
    (: material :)
    for $material in $entry//vra:materialSet/vra:material
        return
            <tr>
                <td class="collection-label">Material</td><td>{$material}</td>
            </tr>
    ,
    (: technique :)
    for $technique in $entry//vra:techniqueSet/vra:technique
        return
            <tr>
                <td class="collection-label">Technique</td><td>{$technique}</td>
            </tr>
    ,
    (: measurements :)
        let $measurements := $entry//vra:measurementsSet/vra:measurements  
        let $measurements := 
            for $measurement in $measurements
                let $type := $measurement/@type/string()
                let $unit := $measurement/@unit/string()
                let $measurement := $measurement/text()
                let $display := concat(functx:capitalize-first($type), ': ', $measurement, ' ' , $unit)
                return 
                    $display
        return
            if (count($measurements) gt 0) 
            then
                let $measurements := string-join($measurements, '; ')
                    return
                        <tr>
                            <td class="collection-label">Measurements</td><td>{$measurements}</td>
                        </tr>
            else ()
,
    mods-common:simple-row(concat(replace(request:get-url(), '/retrieve', '/index.html'), '?search-field=ID&amp;value=', $entry/atom:id), 'Stable Link to This Record')}
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
: The <b>wiki-hra-framework:format-list-view</b> function returns the list view of a sequence of VRA records.
: @param $entry a VRA record, processed by clean:cleanup().
: @param $collection the location of the VRA record, with '/db/' removed
: @param $position the position of the record displayed with the search results (this parameter is not used)
: @param $type the type of the record, 'c', 'w', 'i', for colleciton, work, image.
: @param $id the id of the record.
: @return an XHTML span.
:)
declare function wiki-hra-framework:format-list-view($position as xs:string, $entry as element(), $collection as xs:string, $document-uri as xs:string, $node-id as xs:string) as element(span) {
    let $result :=
    <div class="vra-record">
    
    <span class="agent">
    {
    let $author := $entry//atom:name
            return
                $author
    }   
    </span>
    
    <span class="title">
        {$entry//atom:title}
    </span> 
    
    <span class="date">
    {
    let $earliestDate := $entry//vra:dateSet/vra:date[@type eq 'creation']/vra:earliestDate
    let $earliestDate := 
        if (contains($earliestDate, 'T'))
        then functx:substring-before-last-match($earliestDate, 'T')
        else $earliestDate
    let $earliestDate := 
        if ($entry//vra:dateSet/vra:date[@type eq 'creation']/vra:earliestDate[@circa eq 'true'])
        then concat('ca. ', $earliestDate)
        else $earliestDate
    (:let $log := util:log("DEBUG", ("##$earliestDate1): ", $earliestDate)):)
    let $latestDate := $entry//vra:dateSet/vra:date[@type eq 'creation']/vra:latestDate
    let $latestDate := 
        if (contains($latestDate, 'T'))
        then functx:substring-before-last-match($latestDate, 'T')
        else $latestDate
    let $latestDate := 
        if ($entry//vra:dateSet/vra:date[@type eq 'creation']/vra:latestDate[@circa eq 'true'])
        then concat('ca. ', $latestDate)
        else $latestDate
    let $date :=
        if ($earliestDate eq $latestDate)
        then $earliestDate
        else 
            if (($earliestDate and $latestDate))
            then concat($earliestDate, ' - ', $latestDate)
            else ($earliestDate, $latestDate)
    (:let $log := util:log("DEBUG", ("##$date): ", $date)):)
    return
        if ($date) 
        then functx:substring-before-last-match($date, 'T')
        else ()
    }
    </span>
    </div>
    
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

declare function wiki-hra-framework:detail-view-table($item as element(), $currentPos as xs:int) {
    let $isWritable := security:can-write-collection(util:collection-name($item))
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
    let $saved := exists($stored//*[@id = $id])
    let $vra-work := security:get-resource($id)/vra:relationSet/vra:relation
    
    return
        <tr class="pagination-item detail" xmlns="http://www.w3.org/1999/xhtml">
            <td class="pagination-number">{$currentPos}</td>
            <td class="actions-cell">
                <a id="save_{$id}" href="#{$currentPos}" class="save">
                    <img title="{if ($saved) then 'Remove Record from My List' else 'Save Record to My List'}" src="resources/images/{if ($saved) then 'disk_gew.gif' else 'disk.gif'}" class="{if ($saved) then 'stored' else ''}"/>
                </a>
            </td>
            <td class="detail-type" style="vertical-align:top"><img src="resources/images/image.png" title="Still Image"/></td>
            <td style="vertical-align:top;">
                <div id="image-cover-box"> 
                { 
                    if ($vra-work) then
                        (: relids/refid workaround :)
                        for $rel in $vra-work/vra:relationSet/vra:relation
                            let $image-uuid := 
                                if(starts-with(data($rel/@refid), "i_")) then
                                    data($rel/@refid)
                                else 
                                    data($rel/@relids)
                            let $image := security:get-resource($image-uuid)
                            return
                                <p>
                                    {
                                        vra-hra-framework:create-thumbnail-span($image-uuid, xs:boolean(not(security:get-user-credential-from-session()[1] eq "guest")), $vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW, $vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW)                                                                           }
                                </p>
                    else 
                        let $image := collection($config:content-root)//vra:image[@id = $id]
                        return
                                <p>
                                    {
                                        vra-hra-framework:create-thumbnail-span($id, xs:boolean(not(security:get-user-credential-from-session()[1] eq "guest")), $vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW, $vra-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW)                                                                           }
                                </p>
                }
                </div>
            </td>            
            <td class="detail-xml" style="vertical-align:top;">
                { vra-hra-framework:toolbar($item, $isWritable) }
                <!--Zotero does not import vra records <abbr title="{bs:get-item-uri(concat($item, $id-position))}"></abbr>-->
                {
                    let $collection := util:collection-name($item)
                    return
                        try {
                            wiki-hra-framework:format-detail-view(string($currentPos), $item, $collection, $type, $id)
                        } catch * {
                            util:log("DEBUG", "Code: " || $err:code || "Descr.: " || $err:description || " Value: " || $err:value ),
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

declare function wiki:make-paths-above-collection($path as xs:string, $divisor as xs:string, $last-path-step as xs:string) as item()* {
    let $steps := tokenize($path, $divisor)
    let $count := count($steps)
    let $number-of-steps := 1 to $count
    for $step-number in $number-of-steps
        let $paths := string-join(subsequence($steps, 1, $step-number), $divisor)
            for $path in $paths 
                where contains($path, $last-path-step)
                    return $path
        
};

