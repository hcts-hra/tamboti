xquery version "3.0";

module namespace mods-hra-framework = "http://hra.uni-heidelberg.de/ns/mods-hra-framework";

import module namespace vra-hra-framework = "http://hra.uni-heidelberg.de/ns/vra-hra-framework" at "../vra-hra/vra-hra.xqm";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "../../modules/search/security.xqm";
import module namespace clean = "http://exist-db.org/xquery/mods/cleanup" at "../../modules/search/cleanup.xql";

import module namespace functx="http://www.functx.com";
import module namespace json="http://www.json.org";

import module namespace mods-common = "http://exist-db.org/mods/common" at "../../modules/mods-common.xql";
import module namespace tamboti-common = "http://exist-db.org/tamboti/common" at "../../modules/tamboti-common.xql";

declare namespace mods = "http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";
declare namespace ext = "http://exist-db.org/mods/extension";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace mods-editor = "http://hra.uni-heidelberg.de/ns/mods-editor/";

declare variable $mods-hra-framework:THUMB_SIZE_FOR_GRID := 64;
declare variable $mods-hra-framework:THUMB_SIZE_FOR_GALLERY := 128;
declare variable $mods-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW := 256;
declare variable $mods-hra-framework:THUMB_SIZE_FOR_LIST_VIEW := 128;

declare variable $mods-hra-framework:primary-roles := (
    'artist', 'art', 
    'author', 'aut', 
    'composer', 'cmp', 
    'correspondent', 'crp', 
    'creator', 'cre', 
    'director', 'drt', 
    'photographer', 'pht', 
    'reporter', 'rpt')
;


declare function mods-hra-framework:get-item-uri($item-id as xs:string) {
    fn:concat(
        request:get-scheme(),
        "://",
        request:get-server-name(),
        if((request:get-scheme() eq "http" and request:get-server-port() eq 80) or (request:get-scheme() eq "https" and request:get-server-port() eq 443))then "" else fn:concat(":", request:get-server-port()),
        
        fn:replace(request:get-uri(), "/exist/([^/]*)/([^/]*)/.*", "/exist/$1/$2"),
        
        (:fn:substring-before(request:get-url(), "/modules"), :)
        "/item/",
        $item-id
    )
};

declare function mods-hra-framework:get-UUID($item as element()) {
    $item/@ID 
};

declare function mods-hra-framework:get-icon-from-folder($size as xs:int, $collection as xs:string) {
    let $thumb := xmldb:get-child-resources($collection)[1]
    let $imgLink := concat(substring-after($collection, "/db"), "/", $thumb)
    return
        <img src="images/{$imgLink}?s={$size}"/>
};


(:~
    Get the preview icon for a linked image resource or get the thumbnail showing the resource type.
:)
declare function mods-hra-framework:get-icon($size as xs:int, $item, $currentPos as xs:int) {
(:    let $image-url :=:)
(:    (: NB: Refine criteria for existence of image:):)
(:        ( :)
(:            $item/mods:location/mods:url[@access="preview"]/string(), :)
(:            $item/mods:location/mods:url[@displayLabel="Path to Folder"]/string() :)
(:        )[1]:)
    let $type := $item/mods:typeOfResource[1]/string()
    let $hint := 
        if ($type)
        then functx:capitalize-first($type)
        else
            if (in-scope-prefixes($item) = 'xml')
            then 'Unknown Type'
            else 'Extracted Text'
(:    return:)
(:        if (string-length($image-url)) :)
(:        (: Only run if there actually is a URL:):)
(:        (: NB: It should be checked if the URL leads to an image described in the record:):)
(:        then:)
(:            let $image-path := concat(util:collection-name($item), $image-url):)
(:            return:)
(:                if (collection($image-path)) :)
(:                then mods-hra-framework:get-icon-from-folder($size, $image-path):)
(:                else:)
(:                    let $imgLink := concat(substring-after(util:collection-name($item), "/db"), "/", $image-url):)
(:                    return:)
(:                        <img title="{$hint}" src="images/{$imgLink}?s={$size}"/>        :)
(:        else:)
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
                <img title="{$hint}" src="theme/images/{$type}.png"/>
};

declare function mods-hra-framework:toolbar($item as element(), $isWritable as xs:boolean, $id as xs:string) {
    let $home := security:get-home-collection-uri(security:get-home-collection-uri(security:get-user-credential-from-session()[1]))

    let $id := mods-hra-framework:get-UUID($item)

    let $workdir := util:collection-name($item)

    let $workdir := if (ends-with($workdir,'/')) then ($workdir) else ($workdir || '/')
    return
        <div class="actions-toolbar">
            <a target="_new" href="source.xql?id={$id}&amp;clean=yes">
                <img title="View XML Source of Record" src="theme/images/script_code.png"/>
            </a>
            {
                (: if the item's collection is writable, display edit/delete and move buttons :)
                if ($isWritable) then
                    (
                        <a href="../edit/edit.xq?id={$item/@ID}&amp;collection={util:collection-name($item)}&amp;type={$item/mods:extension/*:template}" target="_blank">
                            <img title="Edit MODS Record" src="theme/images/page_edit.png"/>
                        </a>
                        ,
                        <a class="remove-resource" href="#{$id}"><img title="Delete Record" src="theme/images/delete.png"/></a>
                        ,
                        <a class="move-resource" href="#{$id}"><img title="Move Record" src="theme/images/shape_move_front.png"/></a>
                    )
                else
                    ()
            }
            {
                (: button to add a related item :)
                if (security:get-user-credential-from-session()[1] ne "guest") 
                then
                    <a class="add-related" href="#{if ($isWritable) then $workdir else $home}#{$item/@ID}">
                        <img title="Create Related MODS Record" src="theme/images/page_add.png"/>
                    </a>
                else ()
            }
        </div>
};

(: TODO: A lot of restrictions to the first item in a sequence ([1]) have been made; these must all be changed to for-structures or string-joins. :)

(:~
: The <b>mods-hra-framework:format-detail-view</b> function returns the detail view of a MODS record.
: @param $entry a MODS record, processed by clean:cleanup() in session.xql.
: @param $collection-short the location of the MODS record, with '/db/' removed.
: @param $position the position of the record displayed with the search results (this parameter is not used).
: @return an XHTML table.
:)
declare function mods-hra-framework:format-detail-view($position as xs:string, $entry as element(mods:mods), $collection-short as xs:string) as element(table) {
    let $ID := $entry/@ID/string()
    (:let $log := util:log("DEBUG", ("##$ID): ", $ID)):)
    let $entry := mods-common:remove-parent-with-missing-required-node($entry)
    let $global-transliteration := $entry/mods:extension/ext:transliterationOfResource/text()
    let $global-language := $entry/mods:language[1]/mods:languageTerm[1]/text()
    let $result :=
    <table xmlns="http://www.w3.org/1999/xhtml" class="biblio-full">
    {
    <tr>
        <td class="collection-label">Record Location</td>
        <td>
            <div id="file-location-folder" style="display: none;">{xmldb:decode-uri($collection-short)}</div>
            <div class="collection" >
                {replace(replace(xmldb:decode($collection-short), '^' || $config:mods-commons || '/', $config:mods-root || '/'),'^' || $config:users-collection || '/', $config:mods-root || '/')}
            </div>
         </td>
    </tr>
    ,
    <tr>
        <td class="collection-label">Record Format</td>
        <td>
            <div id="record-format" style="display:none;">MODS</div>
            <div>MODS</div>
        </td>
    </tr>
    ,
    (: names :)
    if ($entry/mods:name)
    then mods-common:names-full($entry, $global-transliteration, $global-language)
    else ()
    ,
    
    (: titles :)
    for $titleInfo in $entry/mods:titleInfo[not(@type eq 'abbreviated')]
    let $titleInfo := mods-common:title-full($titleInfo) 
    return $titleInfo
    ,
    
    (: conferences :)
    mods-common:simple-row(mods-common:get-conference-detail-view($entry), 'Conference')
    ,

    (: place :)
    for $place in $entry/mods:originInfo[1]/mods:place
        return mods-common:simple-row(mods-common:get-place($place), 'Place')
    ,
    
    (: publisher :)
        (: If a transliterated publisher name exists, this probably means that several publisher names are simply different script forms of the same publisher name. Place the transliterated name first, then the original script name. :)
        if ($entry/mods:originInfo[1]/mods:publisher[@transliteration])
        then
            mods-common:simple-row(
                string-join(
                    for $publisher in $entry/mods:originInfo[1]/mods:publisher
                    let $order := 
                        if ($publisher[@transliteration]) 
                        then 0 
                        else 1
                    order by $order
                    return mods-common:get-publisher($publisher)
                , ' ')
            ,
            'Publisher')
        else
        (: Otherwise we have a number of different publishers.:)
            for $publisher in $entry/mods:originInfo[1]/mods:publisher
            return mods-common:simple-row(mods-common:get-publisher($publisher), 'Publisher')
    ,
    
    (: dates :)
    (:If a related item has a date, use it instead of a date in originInfo:)   
    if ($entry/mods:relatedItem[@type eq 'host']/mods:originInfo[1]/mods:dateCreated) 
    then ()
    else 
        for $date in $entry/mods:originInfo[1]/mods:dateCreated
            return mods-common:simple-row($date, 
            concat('Date Created',
                concat(
                if ($date/@point) then concat(' (', functx:capitalize-first($date/@point), ')') else (),
                if ($date/@qualifier) then concat(' (', functx:capitalize-first($date/@qualifier), ')') else ()
                )
                )
            )
    ,
    if ($entry/mods:relatedItem[@type eq 'host']/mods:originInfo[1]/mods:copyrightDate) 
    then () 
    else 
        for $date in $entry/mods:originInfo[1]/mods:copyrightDate
            return mods-common:simple-row($date, 
            concat('Copyright Date',
                concat(
                if ($date/@point) then concat(' (', functx:capitalize-first($date/@point), ')') else (),
                if ($date/@qualifier) then concat(' (', functx:capitalize-first($date/@qualifier), ')') else ()
                )
                )
            )
    ,
    if ($entry/mods:relatedItem[@type eq 'host']/mods:originInfo[1]/mods:dateCaptured) 
    then () 
    else 
        for $date in $entry/mods:originInfo[1]/mods:dateCaptured
            return mods-common:simple-row($date, 
            concat('Date Captured',
                concat(
                if ($date/@point) then concat(' (', functx:capitalize-first($date/@point), ')') else (),
                if ($date/@qualifier) then concat(' (', functx:capitalize-first($date/@qualifier), ')') else ()
                )
                )
            )            
    ,
    if ($entry/mods:relatedItem[@type eq 'host']/mods:originInfo[1]/mods:dateValid) 
    then () 
    else 
        for $date in $entry/mods:originInfo[1]/mods:dateValid
            return mods-common:simple-row($date, 
            concat('Date Valid',
                concat(
                if ($date/@point) then concat(' (', functx:capitalize-first($date/@point), ')') else (),
                if ($date/@qualifier) then concat(' (', functx:capitalize-first($date/@qualifier), ')') else ()
                )
                )
            )
    ,
    if ($entry/mods:relatedItem[@type eq 'host']/mods:originInfo[1]/mods:dateIssued) 
    then () 
    else 
        for $date in $entry/mods:originInfo[1]/mods:dateIssued
            return mods-common:simple-row($date, 
            concat(
                'Date Issued', 
                concat(
                if ($date/@point) then concat(' (', functx:capitalize-first($date/@point), ')') else (),
                if ($date/@qualifier) then concat(' (', functx:capitalize-first($date/@qualifier), ')') else ()
                )
                )
            )
    ,
    if ($entry/mods:relatedItem[@type eq 'host']/mods:originInfo[1]/mods:dateModified) 
    then () 
    else 
        for $date in $entry/mods:originInfo[1]/mods:dateModified
            return mods-common:simple-row($date, 
            concat('Date Modified',
                concat(
                if ($date/@point) then concat(' (', functx:capitalize-first($date/@point), ')') else (),
                if ($date/@qualifier) then concat(' (', functx:capitalize-first($date/@qualifier), ')') else ()
                )
                )
            )
    ,
    if ($entry/mods:relatedItem[@type eq 'host']/mods:originInfo[1]/mods:dateOther) 
    then () 
    else 
        for $date in $entry/mods:originInfo[1]/mods:dateOther
            return mods-common:simple-row($date, 
            concat('Other Date',
                concat(
                if ($date/@point) then concat(' (', functx:capitalize-first($date/@point), ')') else (),
                if ($date/@qualifier) then concat(' (', functx:capitalize-first($date/@qualifier), ')') else ()
                )
                )
            )            
    ,
    (: edition :)
    if ($entry/mods:originInfo[1]/mods:edition) 
    then mods-common:simple-row($entry/mods:originInfo[1]/mods:edition[1], 'Edition') 
    else ()
    ,
    (: extent :)
    let $extent := $entry/mods:physicalDescription/mods:extent
    return
        if ($extent) 
        then 
            for $extent in $extent
                return
                    mods-common:simple-row(
                    mods-common:get-extent($extent), 
                    concat('Extent', 
                        if ($extent/@unit) 
                        then concat(' (', functx:capitalize-first($extent/@unit), ')') 
                        else ()
                        )
                    )    
        else ()
    ,
    (: URL :)
    for $url in $entry/mods:location/mods:url[./text()]
    let $displayLabel := $url/@displayLabel/string()
    let $dateLastAccessed := $url/@displayLabel/string()
    return
        <tr xmlns="http://www.w3.org/1999/xhtml">
            <td class="label"> 
            {
                concat(
                    if ($url/@displayLabel/string())
                    then $url/@displayLabel/string()
                    else 'URL'
                ,
                    if ($url/@dateLastAccessed/string())
                    then concat(' (Last Accessed: ', $url/@dateLastAccessed/string(), ')')
                    else ''
                )
            }
            </td>
            <td class="record">
            {mods-common:format-url($url, $collection-short)}</td>
        </tr>
    ,
    (: location :)
    let $locations := $entry/mods:location[(* except mods:url)]
    for $location in $locations
        return
            <tr xmlns="http://www.w3.org/1999/xhtml">
                <td class="label">Location</td>
                <td class="record">
                {mods-common:format-location($location, $collection-short)}</td>
            </tr>
    ,
    (: relatedItem :)
    mods-common:get-related-items($entry, 'detail', $global-language, $collection-short)
    ,
    (: subject :)
    (: We assume that there are no subjects with an empty topic element. If it is empty, we skip processing.:)
    if (normalize-space(string($entry/mods:subject[1])))
    then mods-common:format-subjects($entry, $global-transliteration, $global-language)    
    else ()
    , 
    (: table of contents :)
    for $table-of-contents in $entry/mods:tableOfContents
    return
        if (string($table-of-contents)) 
        then        
            <tr xmlns="http://www.w3.org/1999/xhtml">
                <td class="label"> 
                {
                    if ($table-of-contents/@displayLabel)
                    then $table-of-contents/@displayLabel
                    else 'Table of Contents'
                }
                </td>
                <td class="record">
                {
                (:Possibly, both text and link could be displayed.:)
                if ($table-of-contents/text())
                then $table-of-contents/text()
                else
                    if (string($table-of-contents/@xlink:href))
                    then
                        let $url := $table-of-contents/@xlink:href
                        let $url-for-display := replace(replace($url, '([%?])', concat('&#8203;', '$1')), '([\.=&amp;])', concat('$1', '&#8203;'))
                        return
                            <a href="{string($url)}" target="_blank">{$url-for-display}</a>
                    else ()
                }
                </td>
            </tr>
        else ()
        ,
    
    (: find records that refer to the current record if this record is a periodical or an edited volume or a similar kind of publication. :)
    (:NB: This takes time!:)
    (:NB: allowing empty genre to triger this: remove when WSC has genre.:)
    if ($entry/mods:genre = ('series', 'periodical', 'editedVolume', 'newspaper', 'journal', 'festschrift', 'encyclopedia', 'conference publication', 'canonical scripture') or empty($entry/mods:genre)) 
    then
        (:The $ID is passed to the query; when the query is constructed, the hash is appended (application.xql, $biblio:FIELDS). 
        This is necessary since a hash in the URL is interpreted as a fragment identifier and not passed as a param.:)
        let $linked-ID := concat('#',$ID)
        let $linked-records := collection($config:mods-root-minus-temp)//mods:mods[mods:relatedItem[@type = ('host', 'series', 'otherFormat')]/@xlink:href eq $linked-ID]
        let $linked-records-count := count($linked-records)
        return
        if ($linked-records-count eq 0)
        then ()
        else 
            if ($linked-records-count gt 10)
            then
                let $advanced-search-data :=
                    <data>
                        <action />
                        <search-field>XLink</search-field>
                        <value>{$ID}</value>
                        <query-tabs>advanced-search-form</query-tabs>
                    </data>
                return            
                    <tr xmlns="http://www.w3.org/1999/xhtml" class="relatedItem-row">
                        <td class="url label relatedItem-label"> 
                            <a onclick="tamboti.apis.advancedSearchWithData({json:contents-to-json($advanced-search-data)})" href="#">&lt;&lt; Catalogued Contents</a>
                        </td>
                        <td class="relatedItem-record">
                            <span class="relatedItem-span">{$linked-records-count} records</span>
                        </td>
                    </tr>
            else
                for $linked-record in $linked-records
                let $link-ID := $linked-record/@ID/string()
                let $link-contents := 
                    if (string-join($linked-record/mods:titleInfo/mods:title, '')) then 
                        mods-hra-framework:format-list-view('', $linked-record, '') 
                    else 
                        ()
                let $advanced-search-data :=
                    <data>
                        <search-field>XLink</search-field>
                        <value>{$link-ID}</value>
                        <query-tabs>advanced-search-form</query-tabs>
                    </data>                    
                return
                <tr xmlns="http://www.w3.org/1999/xhtml" class="relatedItem-row">
                    <td class="url label relatedItem-label">
                        <a onclick="tamboti.apis.advancedSearchWithData({json:contents-to-json($advanced-search-data)})" href="#">&lt;&lt; Catalogued Contents</a>
                    </td>
                    <td class="relatedItem-record">
                        <span class="relatedItem-span">{$link-contents}</span>
                    </td>
                </tr>
        else ()
    
        ,
    (: typeOfResource :)
    mods-common:simple-row(string($entry/mods:typeOfResource[1]), 'Type of Resource')
    ,
    
    (: internetMediaType :)
    let $internetMediaTypes := $entry/mods:physicalDescription/mods:internetMediaType
    return
        for $internetMediaType in $internetMediaTypes
        return
            mods-common:simple-row(
            (
                let $label := doc(concat($config:edit-app-root, '/code-tables/internet-media-type.xml'))/mods-editor:code-table/mods-editor:items/mods-editor:item[mods-editor:value eq $internetMediaType]/mods-editor:label
                return
                    if ($label) 
                    then $label
                    else $internetMediaType)
            , 'Internet Media Type')
    ,
    
    (: genre :)
    for $genre in ($entry/mods:genre)
    let $authority := string($genre/@authority)
    return   
        mods-common:simple-row(
            if ($authority eq 'local')
                then doc(concat($config:edit-app-root, '/code-tables/genre-local.xml'))/mods-editor:code-table/mods-editor:items/mods-editor:item[mods-editor:value eq $genre]/mods-editor:label
                else
                    if ($authority eq 'marcgt')
                    then doc(concat($config:edit-app-root, '/code-tables/genre-marcgt.xml'))/mods-editor:code-table/mods-editor:items/mods-editor:item[mods-editor:value eq $genre]/mods-editor:label
                    else string($genre)
                , 
                concat(
                    'Genre'
                    , 
                    if ($authority)
                    then
                        if ($authority eq 'marcgt')
                        then ' (MARC Genre Terms)'
                        else concat(' (', $authority, ')')
                    else ()            
            )
    )
    ,
    
    (: abstract :)
    for $abstract in ($entry/mods:abstract)
        let $abstract := concat('&lt;span>', $abstract, '&lt;/span>')
        let $abstract := util:parse-html($abstract)
        let $abstract := $abstract//*:span
            return
                mods-common:simple-row($abstract, 'Abstract')
    ,
    
    (: note :)
    for $note in $entry/mods:note
        let $displayLabel := string($note/@displayLabel)
        let $type := string($note/@type)
        let $text := concat('&lt;span>', $note, '&lt;/span>')
        let $text := util:parse-html($text)    
        let $text := $text//*:span
        for $text in $text
            return        
                mods-common:simple-row($text
                , 
                concat('Note', 
                    concat(
                    if ($displayLabel)
                    then concat(' (', $displayLabel, ')')            
                    else ()
                    ,
                    if ($type)
                    then concat(' (', $type, ')')            
                    else ()
                    )
                    )
                )
    ,

    (: language of resource :)
    let $distinct-language-labels := distinct-values(
        for $language in $entry/mods:language
        for $languageTerm in $language/mods:languageTerm
        return mods-common:get-language-label($languageTerm/text())
        )
    let $distinct-language-labels-count := count($distinct-language-labels)
        return
            if ($distinct-language-labels-count gt 0)
            then
                mods-common:simple-row(
                    mods-common:serialize-list($distinct-language-labels, $distinct-language-labels-count)
                ,
                if ($distinct-language-labels-count gt 1) 
                then 'Languages of Resource' 
                else 'Language of Resource'
                    )
            else ()
    ,

    (: script of resource :)
    let $distinct-script-labels := distinct-values(
        for $language in $entry/mods:language
        for $scriptTerm in $language/mods:scriptTerm
        return mods-common:get-script-label($scriptTerm/text())
        )
    let $distinct-script-labels-count := count($distinct-script-labels)
        return
            if ($distinct-script-labels-count gt 0)
            then
                mods-common:simple-row(
                    mods-common:serialize-list($distinct-script-labels, $distinct-script-labels-count)
                ,
                if ($distinct-script-labels-count gt 1) 
                then 'Scripts of Resource' 
                else 'Script of Resource'
                    )
            else ()
    ,
    (: language of cataloging :)
    (:Since there can only be one (default) language of cataloging, the assumption must be that multiple language terms refer to the same language, so just take the first one. 
    Language and script of resource can be multiple.:) 
    let $language-label := $entry/mods:recordInfo/mods:languageOfCataloging/mods:languageTerm[1]
    let $language-label := 
        if ($language-label)
        then mods-common:get-language-label($language-label)
        else ()
    return
        if ($language-label)
        then mods-common:simple-row($language-label, 'Language of Cataloging')
        else ()
    ,
    
    (: script of cataloging :)
    (:Since there can only be one (default) script of cataloging, the assumption must be that multiple script terms refer to the same script, so just take the first one. 
    Language and script of resource can be multiple.:)
    let $script-label := $entry/mods:recordInfo/mods:languageOfCataloging/mods:scriptTerm[1]
    let $script-label := 
        if ($script-label)
        then mods-common:get-script-label($script-label)
        else ()
    return
        if ($script-label)
        then mods-common:simple-row($script-label, 'Script of Cataloging')
        else ()
    ,

    (: identifier :)
    let $identifiers := $entry/mods:identifier
    for $identifier in $identifiers
    let $type := $identifier/@type/string()
    let $type := doc(concat($config:edit-app-root, "/code-tables/identifier-type.xml"))/mods-editor:code-table/mods-editor:items/mods-editor:item[mods-editor:value eq $type]/mods-editor:label
    return 
        mods-common:simple-row
        (
            if ($identifier/@type = 'doi')
            then <a href="http://dx.doi.org/{$identifier/text()}" target="_blank">{$identifier/text()}</a>
            else $identifier/text(), 
            concat
            (
                'Identifier',
                if (string($type)) 
                then concat(
                    ' (', $type, ')'
                )
                else ' (unknown type)'
                , 
                if ($type eq 'local')
                then
                    let $local-identifiers := collection($config:mods-root-minus-temp)//mods:mods[.//mods:identifier eq $identifier]/@ID/string()
                    let $local-identifiers := 
                        (for $local-identifier in $local-identifiers where $local-identifier ne $ID return $local-identifier)
                    return
                    (:warn about duplications of local ids:)
                        if (count($local-identifiers) gt 0)
                        then concat(' NB: This identifier has already been used on record(s) with the following IDs: ', string-join($local-identifiers, ', '))
                        else ()
                else ()
            )
        )
    ,
    
    (: classification :)
    for $item in $entry/mods:classification
    let $authority := 
        if (string($item/@authority)) 
        then concat(' (', (string($item/@authority)), ')') 
        else ()
    return mods-common:simple-row($item, concat('Classification', $authority))
    ,
    
    (: last modification date :)
    let $last-modified := $entry/mods:extension/ext:modified/ext:when
    return 
        if ($last-modified) then
            mods-common:simple-row(functx:substring-before-last-match($last-modified[count(.)], 'T'), 'Record Last Modified')
        else ()
    ,
    let $server := request:get-scheme() || "://" || request:get-server-name() || ":" || request:get-server-port()
    let $stable-link-href := '/exist/apps/tamboti/modules/search/index.html' || '?search-field=ID&amp;value=' || $ID
    let $stable-link-node :=
            <tr>
                <td class="collection-label">Stable link to this record</td>
                <td>
                    <a href="{$stable-link-href}" target="_blank">{$server || $stable-link-href}</a>
                </td>
            </tr>
    return $stable-link-node
    ,
    if (contains($collection-short, 'Priya Paul Collection')) 
    then 
    let $link := concat('http://kjc-fs1.kjc.uni-heidelberg.de:8080/exist/apps/ppcoll/modules/search/index.html', '?search-field=ID&amp;value=', $ID, '&amp;query-tabs=advanced-search-form')
    return
    mods-common:simple-row(
        <a target="_blank" href="{$link}">{$link}</a>, 'View Full Record with Image in The Priya Paul Collection') 
    else ()
    }
    </table>
    
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


declare function mods-hra-framework:detail-view-table($item as element(mods:mods), $currentPos as xs:int) {
    let $isWritable := security:can-write-collection(util:collection-name($item))
    let $document-uri := document-uri(root($item))
    let $id := concat($document-uri, '#', util:node-id($item))
    let $stored := session:get-attribute("personal-list")
    let $saved := exists($stored//*[@id = $id])
    let $results :=  collection($config:mods-root)//mods:mods[@ID=$item/@ID]/mods:relatedItem
    return
        <tr class="pagination-item detail" xmlns="http://www.w3.org/1999/xhtml">
            <td><input class="search-list-item-checkbox" type="checkbox" data-tamboti-record-id="{$item/@ID}"/></td>
            <td class="pagination-number">{$currentPos}</td>
            <td class="actions-cell">
                <a id="save_{$id}" href="#{$currentPos}" class="save">
                    <img title="{if ($saved) then 'Removes Record from My List' else 'Save Record to My List'}" src="theme/images/{if ($saved) then 'disk_gew.gif' else 'disk.gif'}" class="{if ($saved) then 'stored' else ''}"/>
                </a>
            </td>
            <td class="magnify detail-type">
            { mods-hra-framework:get-icon($mods-hra-framework:THUMB_SIZE_FOR_DETAIL_VIEW, $item, $currentPos)}
            </td>
            <td style="vertical-align:top;">
               <div id="image-cover-box" > 
                {
                   let $image-return :=
                            for $entry in $results
                            let $image-is-preview := $entry//mods:typeOfResource eq 'still image' and  $entry//mods:url[@access eq 'preview']
                            let $print-image :=
                                if ($image-is-preview) then 
                                    let $image := collection($config:mods-root)//vra:image[@id=data($entry//mods:url)]
                                    return 
                                       <p>{vra-hra-framework:return-thumbnail-detail-view($image)}</p>
                                else()
                        return $print-image
                   let $elements := for $element in  $item/node()
                        return  $element
                      
                  return $image-return
                  }
                </div>
            </td>
            
            <td class="detail-xml" style="vertical-align:top;">
                { mods-hra-framework:toolbar($item, $isWritable, $id) }
                <abbr class="unapi-id" title="{mods-hra-framework:get-item-uri($item/@ID)}"></abbr>
                {
                    let $collection := util:collection-name($item)
                    let $collection := functx:replace-first($collection, '/db/', '')
                    let $clean := clean:cleanup($item)
                    return
                     try {
                            mods-hra-framework:format-detail-view(string($currentPos), $clean, $collection)
                        } catch * {
                        <td class="error" colspan="2">
                        {$config:error-message-before-link} 
                        <a href="{$config:error-message-href}{$item/@ID/string()}.">{$config:error-message-link-text}</a>
                        {$config:error-message-after-link}
                        </td>
                        }
                
                        (: What is $currentPos used for? :)
                }
            </td>
        </tr>
};

(:~
: The <b>mods-hra-framework:format-list-view</b> function returns the list view of a sequence of MODS records.
: @param $entry a MODS record, processed by clean:cleanup().
: @param $collection-short the location of the MODS record, with '/db/' removed
: @param $position the position of the record displayed with the search results (this parameter is not used)
: @return an XHTML span.
:)
declare function mods-hra-framework:format-list-view($position as xs:string, $entry as element(mods:mods), $collection-short as xs:string) as element(span) {
    let $entry := mods-common:remove-parent-with-missing-required-node($entry)
    (:let $log := util:log("DEBUG", ("##$ID): ", $entry/@ID/string())):)
    let $global-transliteration := $entry/mods:extension/ext:transliterationOfResource/text()
    let $global-language := $entry/mods:language[1]/mods:languageTerm[1]/text()
    return
    let $result :=
        (
        (: The author, etc. of the primary publication. These occur in front, with no role labels.:)
        (: NB: conference? :)
        let $names := $entry/mods:name
        let $names-primary := 
            <primary-names>{
                $names
                    [@type = ('personal', 'corporate', 'family') or not(@type)]
                    [(mods:role/mods:roleTerm[lower-case(.) = $mods-hra-framework:primary-roles]) or empty(mods:role/mods:roleTerm)]
            }</primary-names>
            return
                if (string($names-primary))
                then (mods-common:format-multiple-names($names-primary, 'list-first', $global-transliteration, $global-language)
                , '. ')
                else ()
        ,
        (: The title of the primary publication. :)
        mods-common:get-short-title($entry)
        ,
        let $names := $entry/mods:name
        let $role-terms-secondary := $names/mods:role/mods:roleTerm[not(lower-case(.) = $mods-hra-framework:primary-roles)]
            return
                for $role-term-secondary in distinct-values($role-terms-secondary) 
                    return
                        let $names-secondary := <entry>{$entry/mods:name[mods:role/lower-case(mods:roleTerm) = $role-term-secondary]}</entry>
                            return                            (
                                (: Introduce secondary role label with comma. :)
                                (: NB: What if there are multiple secondary roles? :)
                                ', '
                                ,
                                mods-common:get-role-label-for-list-view($role-term-secondary)
                                ,
                                (: Terminate secondary role with period if there is no related item. :)
                                mods-common:format-multiple-names($names-secondary, 'secondary', $global-transliteration, $global-language)
                                )
        ,
        (:If there are no secondary names, insert a period after the title, if there is no related item.:)
        if (not($entry/mods:name/mods:role/mods:roleTerm[not(lower-case(.) = $mods-hra-framework:primary-roles)]))
        then
            if (not($entry/mods:relatedItem[@type eq 'host'])) 
            then ''
            else '.'
        else ()
        , ' '
        ,
        (: The conference of the primary publication, containing originInfo and part information. :)
        if ($entry/mods:name[@type eq 'conference']) 
        then mods-common:get-conference-hitlist($entry)
        (: If not a conference publication, get originInfo and part information for the primary publication. :)
        else 
            (:The series that the primary publication occurs in is spliced in between the secondary names and the originInfo.:)
            (:NB: Should not be  italicised.:)
            if ($entry/mods:relatedItem[@type eq 'series'])
            then ('. ', <span xmlns="http://www.w3.org/1999/xhtml" class="relatedItem-span">{mods-common:get-related-items($entry, 'list', $global-language, $collection-short)}</span>)
            else ()
        ,
        mods-common:get-part-and-origin($entry)
        ,
        (: The periodical, edited volume or series that the primary publication occurs in. :)
        (: if ($entry/mods:relatedItem[@type=('host','series')]/mods:part/mods:extent or $entry/mods:relatedItem[@type=('host','series')]/mods:part/mods:detail/mods:number/text()) :)
        if ($entry/mods:relatedItem[@type eq 'host'])
        then <span xmlns="http://www.w3.org/1999/xhtml" class="relatedItem-span">{mods-common:get-related-items($entry, 'list', $global-language, $collection-short)}</span>
        else 
        (: The url of the primary publication. :)
            if (contains($collection-short, 'Priya')) then () else
            if ($entry/mods:location/mods:url/text())
            then
                for $url in $entry/mods:location/mods:url
                    return
                        let $url-for-display := replace(replace($url, '([%?])', concat('&#8203;', '$1')), '([\.=&amp;])', concat('$1', '&#8203;')) 
                        return
                            (: NB: The link is not clickable. :)
                            concat(' <', $url-for-display, '>', '.')
            else '.'
        )
    
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

declare function mods-hra-framework:list-view-table($item as node(), $currentPos as xs:int) {
    let $id := concat(document-uri(root($item)), '#', util:node-id($item))
    let $stored := session:get-attribute("personal-list")
    let $saved := exists($stored//*[@id = $id])
    return
        <tr xmlns="http://www.w3.org/1999/xhtml" class="pagination-item list">
            <td><input class="search-list-item-checkbox" type="checkbox" data-tamboti-record-id="{$item/@ID}"/></td>
            <td class="pagination-number">{$currentPos}</td>
            {
            <td class="actions-cell">
                <a id="save_{$id}" href="#{$currentPos}" class="save">
                    <img title="{if ($saved) then 'Remove Record from My List' else 'Save Record to My List'}" src="theme/images/{if ($saved) then 'disk_gew.gif' else 'disk.gif'}" class="{if ($saved) then 'stored' else ''}"/>
                </a>
            </td>
            }
            <td class="list-type icon magnify">
            { mods-hra-framework:get-icon($mods-hra-framework:THUMB_SIZE_FOR_LIST_VIEW, $item, $currentPos)}
            </td>
            <td/>
            {
            <td class="pagination-toggle">
                <abbr class="unapi-id" title="{mods-hra-framework:get-item-uri($item/@ID)}"></abbr>
                <a>
                {
                    let $collection := util:collection-name($item)
                    let $collection := functx:replace-first($collection, '/db/', '')
                    let $clean := clean:cleanup($item)
                    return
                     try {
                            mods-hra-framework:format-list-view(string($currentPos), $clean, $collection)
                        } catch * {
                        <td class="error" colspan="2">
                        {$config:error-message-before-link} 
                        <a href="{$config:error-message-href}{$item/@ID/string()}.">{$config:error-message-link-text}</a>
                        {$config:error-message-after-link}
                        </td>
                        }                        
                        (: Originally $item was passed to retrieve-mods:format-list-view() - was there a reason for that? Performance? :)
                }
                </a>
            </td>
            }
        </tr>
};


declare function mods-hra-framework:move-resource($resource-id as xs:string, $destination-collection as xs:string) as element(status) {
    
    let $resource := collection($config:mods-root-minus-temp)//mods:mods[@ID eq $resource-id][1]
    let $resource-name := $resource-id || ".xml"    
    let $resource-collection := substring-before(base-uri($resource), $resource-name)
    let $destination-path := $destination-collection || "/" || $resource-name
    let $move-record :=
        (
            xmldb:move($resource-collection, $destination-collection, $resource-name),
            security:apply-parent-collection-permissions($destination-path)
        )
        
    return <status moved="{$resource-name}" from="{$resource-collection}" to="{$destination-collection}" />
    
};

declare function mods-hra-framework:move-resource($source-collection as xs:anyURI, $target-collection as xs:anyURI, $resource-id as xs:string) as element(status) {
    let $resource-name := util:document-name(collection($source-collection)//mods:mods[@ID = $resource-id][1])
    let $result :=
        system:as-user(security:get-user-credential-from-session()[1], security:get-user-credential-from-session()[2],
            (
                xmldb:move($source-collection, $target-collection, $resource-name)
                ,
                (: clear ACL and copy ACL and POSIX-rights from parent collection :)
                sm:clear-acl(xs:anyURI($target-collection || "/" || $resource-name))
                ,
                security:duplicate-acl($target-collection, xs:anyURI($target-collection || "/" || $resource-name))
                ,
                security:copy-owner-and-group(xs:anyURI($target-collection), xs:anyURI($target-collection || "/" || $resource-name))
            )
        )

    return
        if($result) then
            <status moved="{$resource-name}" from="{$source-collection}" to="{$target-collection}">{$target-collection}</status>
        else
            <status id="error">Error trying to move</status>
};

declare function mods-hra-framework:remove-resource($document-uri as xs:anyURI){
    let $doc := doc($document-uri)
    let $resource-id := $doc/mods:mods/@ID/string()
    let $xlink := concat('#', $resource-id)
    (:since xlinks are also inserted manually, check also for cases when the pound sign has been forgotten:)
    let $xlink-recs := collection($config:mods-root-minus-temp)//mods:relatedItem[@xlink:href = ($xlink, $resource-id)]
    return
        try {
            let $result := 
                (: ToDo: if the resource is linked: handle it:)
                if (count($xlink-recs/..) = 0) then
                    xmldb:remove(util:collection-name($doc), util:document-name($doc))
                else
                    let $log := util:log("DEBUG", "Prevented removing resource " || $resource-id || ": it has " || count($xlink-recs/..) || " xlinks")
                    return 
                        false()
            return
                true()
        } catch * {
            let $log := util:log("DEBUG", "Error: remove resource failed: " ||  $err:code || ": " || $err:description)
            return
                false()
        }
};
