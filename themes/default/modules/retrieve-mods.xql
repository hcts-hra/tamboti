module namespace retrieve-mods="http://exist-db.org/mods/retrieve";

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace mads="http://www.loc.gov/mads/v2";
declare namespace xlink="http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";
declare namespace ext="http://exist-db.org/mods/extension";
declare namespace html="http://www.w3.org/1999/xhtml";

import module namespace config="http://exist-db.org/mods/config" at "../../../modules/config.xqm";
import module namespace uu="http://exist-db.org/mods/uri-util" at "../../../modules/search/uri-util.xqm";
import module namespace tamboti-common="http://exist-db.org/tamboti/common" at "../../../modules/tamboti-common.xql";
import module namespace mods-common="http://exist-db.org/mods/common" at "../../../modules/mods-common.xql";

(:The $retrieve-mods:primary-roles values are lower-cased when compared.:)
declare variable $retrieve-mods:primary-roles := (
    'artist', 'art', 
    'author', 'aut', 
    'composer', 'cmp', 
    'correspondent', 'crp', 
    'creator', 'cre', 
    'director', 'drt', 
    'photographer', 'pht', 
    'reporter', 'rpt')
;

declare option exist:serialize "media-type=text/xml";

(: TODO: A lot of restrictions to the first item in a sequence ([1]) have been made; these must all be changed to for-structures or string-joins. :)

(:~
: The functx:substring-before-last-match function returns the part of $arg that appears before the last match of $regex. 
: If $arg does not match $regex, the entire $arg is returned. 
: If $arg is the empty sequence, the empty sequence is returned.
: @author Jenny Tennison
: @param $arg the string to substring
: @param $regex the regular expression (string)
: @return xs:string?
: @see http://www.xqueryfunctions.com/xq/functx:substring-before-last-match.html 
:)
declare function functx:substring-before-last-match($arg as xs:string, $regex as xs:string) as xs:string? {       
   replace($arg,concat('^(.*)',$regex,'.*'),'$1')
} ;
 
(:~
: The functx:camel-case-to-words function turns a camel-case string 
: (one that uses upper-case letters to start new words, as in "thisIsACamelCaseTerm"), 
: and turns them into a string of words using a space or other delimiter.
: Used to transform the camel-case names of MODS elements into space-separated words.
: @author Jenny Tennison
: @param $arg the string to modify
: @param $delim the delimiter for the words (e.g. a space)
: @return xs:string
: @see http://www.xqueryfunctions.com/xq/functx_camel-case-to-words.html
:)
declare function functx:camel-case-to-words($arg as xs:string?, $delim as xs:string ) as xs:string {
   concat(substring($arg,1,1), replace(substring($arg,2),'(\p{Lu})', concat($delim, '$1')))
};

(:~
: The functx:capitalize-first function capitalizes the first character of $arg. 
: If the first character is not a lowercase letter, $arg is left unchanged. 
: It capitalizes only the first character of the entire string, not the first letter of every word.
: @author Jenny Tennison
: @param $arg the word or phrase to capitalize
: @return xs:string?
: @see http://www.xqueryfunctions.com/xq/functx_capitalize-first.html
:)
declare function functx:capitalize-first($arg as xs:string?) as xs:string? {       
   concat(upper-case(substring($arg,1,1)),
             substring($arg,2))
};

(:~
: The <b>retrieve-mods:format-detail-view</b> function returns the detail view of a MODS record.
: @param $entry a MODS record, processed by clean:cleanup() in session.xql.
: @param $collection-short the location of the MODS record, with '/db/' removed.
: @param $position the position of the record displayed with the search results (this parameter is not used).
: @return an XHTML table.
:)
declare function retrieve-mods:format-detail-view($position as xs:string, $entry as element(mods:mods), $collection-short as xs:string) as element(table) {
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
                {replace(replace(uu:unescape-collection-path($collection-short), '^resources/commons/', 'resources/'),'^resources/users/', 'resources/')}
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
                        <a href="{string($table-of-contents/@xlink:href)}" target="_blank">
                        {
                            if ((string-length(string($table-of-contents/@xlink:href)) le 70)) 
                            then string($table-of-contents/@xlink:href)
                            (:avoid too long urls that do not line-wrap:)
                            else (substring(string($table-of-contents/@xlink:href), 1, 70), '...')}
                        </a>
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
                <tr xmlns="http://www.w3.org/1999/xhtml" class="relatedItem-row">
                    <td class="url label relatedItem-label"> 
                        <a href="?action=&amp;search-field=XLink&amp;value={$ID}&amp;query-tabs=advanced-search-form">&lt;&lt; Catalogued Contents</a>
                    </td>
                    <td class="relatedItem-record">
                        <span class="relatedItem-span">{$linked-records-count} records</span>
                    </td>
                </tr>
            else
                for $linked-record in $linked-records
                let $link-ID := $linked-record/@ID/string()
                let $link-contents := 
                    if (string-join($linked-record/mods:titleInfo/mods:title, ''))
                    then retrieve-mods:format-list-view('', $linked-record, '') 
                    else ()
                return
                <tr xmlns="http://www.w3.org/1999/xhtml" class="relatedItem-row">
                    <td class="url label relatedItem-label">
                        <a href="?search-field=ID&amp;value={$link-ID}&amp;query-tabs=advanced-search-form">&lt;&lt; Catalogued Contents</a>
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
    mods-common:simple-row(
    (
	    let $label := doc(concat($config:edit-app-root, '/code-tables/internet-media-type-codes.xml'))/*:code-table/*:items/*:item[*:value eq $entry/mods:physicalDescription[1]/mods:internetMediaType]/*:label
	    return
	        if ($label) 
	        then $label
	        else $entry/mods:physicalDescription[1]/mods:internetMediaType)
    , 'Internet Media Type')
    ,
    
    (: genre :)
    for $genre in ($entry/mods:genre)
    let $authority := string($genre/@authority)
    return   
        mods-common:simple-row(
            if ($authority eq 'local')
                then doc(concat($config:edit-app-root, '/code-tables/genre-local-codes.xml'))/*:code-table/*:items/*:item[*:value eq $genre]/*:label
                else
                	if ($authority eq 'marcgt')
                	then doc(concat($config:edit-app-root, '/code-tables/genre-marcgt-codes.xml'))/*:code-table/*:items/*:item[*:value eq $genre]/*:label
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
    let $distinct-language-labels := distinct-values(
        for $language in $entry/mods:recordInfo/mods:languageOfCataloging
        return mods-common:get-language-label($language/mods:languageTerm)
        )
    let $distinct-language-labels-count := count($distinct-language-labels)
        return
            if ($distinct-language-labels-count gt 0)
            then
                mods-common:simple-row(
                    mods-common:serialize-list($distinct-language-labels, $distinct-language-labels-count)
                ,
                if ($distinct-language-labels-count gt 1) 
                then 'Languages of Cataloging' 
                else 'Language of Cataloging'
                    )
            else ()
    ,
    
    (: script of cataloging :)
    let $distinct-script-labels := distinct-values(
        for $language in $entry/mods:recordInfo/mods:languageOfCataloging
        return mods-common:get-script-label($language/mods:scriptTerm)
        )
    let $distinct-script-labels-count := count($distinct-script-labels)
        return
            if ($distinct-script-labels-count gt 0)
            then
                mods-common:simple-row(
                    mods-common:serialize-list($distinct-script-labels, $distinct-script-labels-count)
                ,
                if ($distinct-script-labels-count gt 1) 
                then 'Scripts of Cataloging' 
                else 'Script of Cataloging'
                    )
            else ()
    ,

    (: identifier :)
    let $identifiers := $entry/mods:identifier
    for $identifer in $identifiers
    let $type := $identifer/@type/string()
    let $type := doc(concat($config:edit-app-root, "/code-tables/identifier-type-codes.xml"))/*:code-table/*:items/*:item[*:value eq $type]/*:label
    return 
        mods-common:simple-row
        (
            $identifer/text(), 
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
                    let $local-identifiers := collection($config:mods-root-minus-temp)//mods:mods[.//mods:identifier eq $identifer]/@ID/string()
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
    mods-common:simple-row(concat(replace(request:get-url(), '/retrieve', '/index.html'), '?search-field=ID&amp;value=', $ID), 'Stable Link to This Record')
    ,
    if (contains($collection-short, 'Priya Paul Collection')) 
    then 
    let $link := concat('http://kjc-fs1.kjc.uni-heidelberg.de:8080/exist/apps/ppcoll/modules/search/index.html', '?search-field=ID&amp;value=', $ID, '&amp;query-tabs=advanced-search-form')
    return
    mods-common:simple-row(
        <a target="_blank" href="{$link}">{$link}</a>, 'View Full Record with Image in The Priya Paul Collection') 
    else ()
    ,
    if (contains($collection-short, 'Naddara')) 
    then 
    let $link := concat('http://kjc-fs1.kjc.uni-heidelberg.de:8080/exist/apps/naddara/modules/search/index.html', '?search-field=ID&amp;value=', $ID, '&amp;query-tabs=advanced-search-form')
    return
    mods-common:simple-row(
        <a target="_blank" href="{$link}">{$link}</a>, 'View Full Record with Image in The Abou Naddara Collection') 
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

(:~
: The <b>retrieve-mods:format-list-view</b> function returns the list view of a sequence of MODS records.
: @param $entry a MODS record, processed by clean:cleanup().
: @param $collection-short the location of the MODS record, with '/db/' removed
: @param $position the position of the record displayed with the search results (this parameter is not used)
: @return an XHTML span.
:)
declare function retrieve-mods:format-list-view($position as xs:string, $entry as element(mods:mods), $collection-short as xs:string) as element(span) {
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
                    [(mods:role/mods:roleTerm[lower-case(.) = $retrieve-mods:primary-roles]) or empty(mods:role/mods:roleTerm)]
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
        let $role-terms-secondary := $names/mods:role/mods:roleTerm[not(lower-case(.) = $retrieve-mods:primary-roles)]
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
        if (not($entry/mods:name/mods:role/mods:roleTerm[not(lower-case(.) = $retrieve-mods:primary-roles)]))
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
                    (: NB: Too long URLs do not line-wrap, forcing the display of results down below the folder view, so do not display too long URLs. The link is anyway not clickable. :)
	                if (string-length($url) le 80)
	                then concat(' <', $url, '>', '.')
    	            else ""
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