module namespace retrieve-vra="http://exist-db.org/vra/retrieve";

declare namespace vra="http://www.vraweb.org/vracore4.htm";
declare namespace functx = "http://www.functx.com";

import module namespace config="http://exist-db.org/mods/config" at "../../../modules/config.xqm";
import module namespace tamboti-common="http://exist-db.org/tamboti/common" at "../../../modules/tamboti-common.xql";
import module namespace mods-common="http://exist-db.org/mods/common" at "../../../modules/mods-common.xql";
import module namespace image-link-generator="http://hra.uni-heidelberg.de/ns/tamboti/modules/display/image-link-generator" at "../../../modules/display/image-link-generator.xqm";

(:The $retrieve-vra:primary-roles values are lower-cased when compared.:)
declare variable $retrieve-vra:primary-roles := ('aut', 'author', 'cre', 'creator', 'composer', 'cmp', 'artist', 'art', 'director', 'drt');

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
 

(:~
: The <b>retrieve-vra:format-detail-view</b> function returns the detail view of a VRA record.
: @param $entry a VRA record, processed by clean:cleanup() in session.xql.
: @param $collection-short the location of the VRA record, with '/db/' removed.
: @param $position the position of the record displayed with the search results (this parameter is not used).
: @return an XHTML table.
:)
declare function retrieve-vra:format-detail-view($position as xs:string, $entry as element(vra:vra), $collection-short as xs:string, $type as xs:string, $id as xs:string) as element(table) {
    let $result :=
    <table xmlns="http://www.w3.org/1999/xhtml" class="biblio-full">
    {
    <tr>
        <td class="collection-label">Record Location</td>
        <td><div class="collection">{replace(replace(xmldb:decode($collection-short), '^resources/commons/', 'resources/'),'^resources/users/', 'resources/')}</div></td>
    </tr>
    ,
    let $format := concat('VRA'
        , 
        if ($type eq 'i')
        then ' Image'
        else
            if ($type eq 'w')
            then ' Work'
            else ' Collection'
        ,
        ' Record')
    return
        <tr>
            <td class="collection-label">Record Format</td>
            <td>{$format}</td>
        </tr>
    ,
    (: titles :)
    for $title in $entry//vra:titleSet/vra:title
        return
            <tr>
                <td class="collection-label">Title</td>
                <td>{$title/text()}</td>
            </tr>
    ,
    (: agents :)
    for $agent in $entry//vra:agentSet/vra:agent
        let $name := $agent/vra:name
        let $role := $agent/vra:role
        let $role := mods-common:get-role-term-label-for-detail-view($role)
        let $role := 
            if ($role) 
            then $role
            else 'Agent'
        return
            <tr>
                <td class="collection-label">{$role}</td>
                <td>{$name/text()}</td>
            </tr>
    ,
    (: date :)
    for $date in $entry//vra:dateSet/vra:date
        return
            let $date-type := functx:capitalize-first($date/@type) 
            let $earliestDate := $date/vra:earliestDate
            let $earliestDate := 
                if (contains($earliestDate, 'T'))
                then functx:substring-before-last-match($earliestDate, 'T')
                else $earliestDate
            let $earliestDate := 
                if ($date/vra:earliestDate[@circa eq 'true'])
                then concat('ca. ', $earliestDate)
                else $earliestDate
            (:let $log := util:log("DEBUG", ("##$earliestDate2): ", $earliestDate)):)
            let $latestDate := $date/vra:latestDate
            let $latestDate := 
                if (contains($latestDate, 'T'))
                then functx:substring-before-last-match($latestDate, 'T')
                else $latestDate
            let $latestDate := 
                if ($date/vra:latestDate[@circa eq 'true'])
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
            (:let $log := util:log("DEBUG", ("##$date-type): ", $date-type)):)
            return 
                <tr>
                    <td class="collection-label">{$date-type}</td>
                    <td>{$date}</td>
                </tr>
    ,
    (: location :)
    for $location in $entry//vra:locationSet/vra:location[@source eq 'EXC']for $location in $entry//vra:locationSet/vra:location[@source eq 'EXC']
        return
            <tr>
                <td class="collection-label">{functx:capitalize-first($location/@type/string())}</td><td>{$location/vra:name}</td>
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
    
    let $relations := $entry//vra:relationSet/vra:relation
    for $relation in $relations[@relids]
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
            let $list-view := retrieve-vra:format-list-view('', $list-view, '')
            return
                <tr>
                    <td class="collection-label">{$type}</td>
                    <td>{$list-view}</td>
                </tr>
         ,
       let $href-relation := $entry//vra:relationSet/vra:relation[@href]
       return
           if ($href-relation)
           then
               <tr>
                   <td class="collection-label">
                      <a href="?search-field=ID&amp;value={$href-relation/@href}&amp;query-tabs=advanced-search-form&amp;default-operator=and">{concat('&lt;&lt; ', $href-relation/@type)}</a>
                   </td>
                   <td>Tamboti MODS Record</td>
               </tr>
           else ()
    ,
    
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
    mods-common:simple-row(
        concat(replace(request:get-url(), '/retrieve', '/index.html'), '?search-field=ID&amp;value=', $entry/vra:work/@id), 
        'Stable Link to This Record')
,
    let $title := $entry//vra:titleSet/vra:title[1]/text()
    let $image-id := $entry//vra:relationSet/vra:relation[1]/@relids/string()    
    let $image-href := image-link-generator:generate-href($image-id, "tamboti-size150")

    let $image-url := 
        <code>
            &lt;figure>&lt;img src="{$image-href}" alt="{replace(replace($title, '"', ''), "'", "")}"/>&lt;figcaption>{$title}&lt;/figcaption>&lt;/figure>
        </code>    
        return
    mods-common:simple-row(
        $image-url, 
        'Code to Embed Image')
}
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
: The <b>retrieve-vra:format-list-view</b> function returns the list view of a sequence of VRA records.
: @param $entry a VRA record, processed by clean:cleanup().
: @param $collection-short the location of the VRA record, with '/db/' removed
: @param $position the position of the record displayed with the search results (this parameter is not used)
: @param $type the type of the record, 'c', 'w', 'i', for colleciton, work, image.
: @param $id the id of the record.
: @return an XHTML span.
:)
declare function retrieve-vra:format-list-view($position as xs:string, $entry as element(vra:vra), $collection-short as xs:string) as element(span) {
    let $result :=
    <div class="vra-record">
    
    <span class="agent">
    {
    let $agents := $entry//vra:agentSet/vra:agent
    let $agents := 
    for $agent in $agents[not(vra:role = ('col', 'digitizing', 'Metadata contact'))]
        let $name := $agent/vra:name
        let $role := $agent/vra:role
        let $role := mods-common:get-role-term-label-for-detail-view($role)
        return <span>{concat($name, ' (', $role, ')')}</span>
            return
                if (count($agents) gt 0)
                then concat(string-join($agents, '; '), ': ')
                else ()
    }   
    </span>
    
    <span class="title">
        {string-join($entry//vra:titleSet/vra:title/text(), ' ')}
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
