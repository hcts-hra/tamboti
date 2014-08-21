module namespace retrieve-wiki="http://exist-db.org/wiki/retrieve";

declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace functx = "http://www.functx.com";
declare namespace vra="http://www.vraweb.org/vracore4.htm";(:delete when finished:)
declare namespace wiki="http://exist-db.org/xquery/wiki";

import module namespace config="http://exist-db.org/mods/config" at "../../../modules/config.xqm";
import module namespace tamboti-common="http://exist-db.org/tamboti/common" at "../../../modules/tamboti-common.xql";
import module namespace mods-common="http://exist-db.org/mods/common" at "../../../modules/mods-common.xql";

declare option exist:serialize "media-type=text/xml";

(:~
: The functx:substring-before-last-match function returns the part of $arg that appears before the last match of $regex. 
: If $arg does not match $regex, the entire $arg is returned. 
: If $arg is the empty sequence, the empty sequence is returned.
: @author Jenny Tennison
: @param $arg the string to substring
: @param $regex the regular expression (string)
: @return xs:string?
: @see http://www.xqueryfunctions.com/xq/functx_substring-before-last-match.html 
:)
declare function functx:substring-before-last-match($arg as xs:string, $regex as xs:string) as xs:string? {       
   replace($arg,concat('^(.*)',$regex,'.*'),'$1')
} ;
 
(:~
: The functx:camel-case-to-words function turns a camel-case string 
: (one that uses upper-case letters to start new words, as in "thisIsACamelCaseTerm"), 
: and turns them into a string of words using a space or other delimiter.
: Used to transform the camel-case names of VRA elements into space-separated words.
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

(:~
: The <b>retrieve-wiki:format-detail-view</b> function returns the detail view of a VRA record.
: @param $entry a VRA record, processed by clean:cleanup() in session.xql.
: @param $collection the location of the VRA record, with '/db/' removed.
: @param $position the position of the record displayed with the search results (this parameter is not used).
: @return an XHTML table.
:)
declare function retrieve-wiki:format-detail-view($position as xs:string, $entry as element(), $collection as xs:string, $type as xs:string, $id as xs:string) as element(table) {
    (:let $log := util:log("DEBUG", ("##$entry11): ", $entry)):)
    let $result :=
    <table xmlns="http://www.w3.org/1999/xhtml" class="biblio-full">
    {
    <tr>
        <td class="collection-label">Record Location</td>
        <td><div class="collection">{replace(replace(xmldb:decode-uri($collection), '^resources/commons/', 'resources/'),'^resources/users/', 'resources/')}</div></td>
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
            let $list-view := collection($config:mods-root)//vra:image[@id = $relid]/..
            let $list-view := retrieve-wiki:format-list-view('', $list-view, '')
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
                            <td class="collection-label">Measuremenets</td><td>{$measurements}</td>
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
: The <b>retrieve-wiki:format-list-view</b> function returns the list view of a sequence of VRA records.
: @param $entry a VRA record, processed by clean:cleanup().
: @param $collection the location of the VRA record, with '/db/' removed
: @param $position the position of the record displayed with the search results (this parameter is not used)
: @param $type the type of the record, 'c', 'w', 'i', for colleciton, work, image.
: @param $id the id of the record.
: @return an XHTML span.
:)
declare function retrieve-wiki:format-list-view($position as xs:string, $entry as element(), $collection as xs:string, $document-uri as xs:string, $node-id as xs:string) as element(span) {
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