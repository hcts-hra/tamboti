xquery version "3.0";

(:~
    Returns the list of distinct title words, names, dates, and subjects occurring in the result set.
    The query is called via AJAX when the user expands one of the headings in the
    "filter" box.
    The title words are derived from the Lucene index. The names rely on names:format-name() and are therefore expensive.
:)
import module namespace names="http://exist-db.org/xquery/biblio/names"
    at "names.xql";
import module namespace mods-common="http://exist-db.org/mods/common"
    at "../mods-common.xql";
import module namespace config="http://exist-db.org/mods/config" at "../config.xqm";

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";

declare option exist:serialize "method=xhtml enforce-xhtml=yes";

declare variable $local:MAX_RECORD_COUNT := 13000;
declare variable $local:MAX_RESULTS_TITLES := 1500;
declare variable $local:MAX_TITLE_WORDS := 1000;
declare variable $local:MAX_RESULTS_DATES := 1300;
declare variable $local:MAX_RESULTS_NAMES := 1500;
declare variable $local:MAX_RESULTS_SUBJECTS := 750;
declare variable $local:SEARCH-COLLECTION := session:get-attribute('query');

declare function local:key($key, $options) {
    <li><a href="?filter=Title&amp;value={$key}&amp;query-tabs=advanced-search-form&amp;default-operator=and&amp;collection={$local:SEARCH-COLLECTION//collection}">{$key} ({$options[1]})</a></li>
};

declare function local:keywords($results as element()*, $record-count as xs:integer) {
    let $max-terms := 
        if ($record-count ge $local:MAX_RESULTS_TITLES) 
        then $local:MAX_TITLE_WORDS 
        else ()
    let $prefixParam := request:get-parameter("prefix", "")
    let $prefix := if (empty($max-terms)) then "" else $prefixParam
    let $callback := util:function(xs:QName("local:key"), 2)
return
    (: NB: Is there any way to get the number of title words? :)
    if ($record-count gt $local:MAX_RECORD_COUNT) 
    then
        <li>There are too many records ({$record-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RECORD_COUNT}.</li>
    else
        <ul class="{if (empty($max-terms)) then 'complete' else $max-terms}">
        { util:index-keys($results//(mods:titleInfo | vra:titleSet), $prefix, $callback, $max-terms, "lucene-index") }
        </ul>
};

let $type := request:get-parameter("type", ())
let $record-count := count(session:get-attribute("mods:cached"))
(: There is a load problem with setting this variable to the cache each time a facet button is clicked. 
10,000 records amount to about 20 MB and several people could easily access this function at the same time. 
Even if the cache contains too many items and we do not allow it to be processed, it still takes up memory. 
The size has been set to 13,000, to accommodate the largest collection. 
If the result set is larger than that, a message is shown. :)
let $cached := 
    if ($record-count gt $local:MAX_RECORD_COUNT) 
    then ()
    else session:get-attribute("mods:cached")
return
    if ($type eq 'name') 
    then
        <ul>
        {
            let $names := $cached//(mods:name | vra:agentSet)
            let $names-count := count(distinct-values($names))
            return
                if ($names-count gt $local:MAX_RESULTS_NAMES) 
                then
                    <li>There are too many names ({$names-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RESULTS_NAMES}.</li>
                else
                    if ($record-count gt $local:MAX_RECORD_COUNT)
                    then
                        <li>There are too many records ({$record-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RECORD_COUNT}.</li>
                    else
                        let $authors :=
                            for $author in $names
                            return 
                                names:format-name($author)
                                    let $distinct := distinct-values($authors)
                                    for $name in $distinct
                                    order by upper-case($name) empty greatest
                                    return
                                        <li><a href="?filter=Name&amp;value={$name}&amp;query-tabs=advanced-search-form&amp;default-operator=and&amp;collection={$local:SEARCH-COLLECTION//collection}">{$name}</a></li>
            }
            </ul>
    else
        if ($type eq 'date') 
        then
            <ul>
            {
                let $dates :=
                    distinct-values(
                    (
                    	$cached/mods:originInfo/mods:dateIssued,
                    	$cached/mods:originInfo/mods:dateCreated,
                    	$cached/mods:originInfo/mods:copyrightDate,
                    	$cached/mods:relatedItem/mods:originInfo/mods:copyrightDate,
                    	$cached/mods:relatedItem/mods:originInfo/mods:dateIssued,
                    	$cached/mods:relatedItem/mods:part/mods:date
                	)
                	)
                let $dates-count := count($dates)
                return
                    if ($dates-count gt $local:MAX_RESULTS_DATES) 
                    then
                        <li>There are too many dates ({$dates-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RESULTS_DATES}.</li>
                    else
                        if ($record-count gt $local:MAX_RECORD_COUNT) 
                        then
                            <li>There are too many records ({$record-count})to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RECORD_COUNT}.</li>
                        else
                            for $date in $dates
                            order by $date descending
                            return
                                <li><a href="?filter=Date&amp;value={$date}&amp;query-tabs=advanced-search-form&amp;default-operator=and&amp;collection={$local:SEARCH-COLLECTION//collection}">{$date}</a></li>
             }
             </ul>
        else
            if ($type eq 'subject') 
            then
                <ul>
                {
                    let $subjects := distinct-values($cached/(mods:subject | vra:work/vra:subjectSet/vra:subject/vra:term))
                    let $subjects-count := count($subjects)
                    return
                        if ($subjects-count gt $local:MAX_RESULTS_SUBJECTS)
                        then
                            <li>There are too many subjects ({$subjects-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RESULTS_SUBJECTS}.</li>
                        else
                            if ($record-count gt $local:MAX_RECORD_COUNT)
                            then
                                <li>There are too many records ({$record-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RECORD_COUNT}.</li>
                            else
                                (:No distinction is made between different kinds of subjects - topics, temporal, geographic, etc.:)
                                for $subject in $subjects
                                order by upper-case($subject) ascending
                                return
                                    (:LCSH have '--', so they have to be replaced.:)
                                    <li><a href="?filter=Subject&amp;value={replace($subject, '-', '')}&amp;query-tabs=advanced-search-form&amp;default-operator=and&amp;collection={$local:SEARCH-COLLECTION//collection}">{$subject}</a></li>
                 }
                 </ul>
             else
                 if ($type eq 'language')
                 then 
                     <ul>
                     {
                        let $languages := distinct-values($cached/(mods:language/mods:languageTerm))
                        let $languages-count := count($languages)
                        return
                            if ($languages-count gt $local:MAX_RESULTS_SUBJECTS)
                            then
                                <li>There are too many languages ({$languages-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RESULTS_SUBJECTS}.</li>
                            else
                                if ($record-count gt $local:MAX_RECORD_COUNT)
                                then
                                    <li>There are too many records ({$record-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RECORD_COUNT}.</li>
                                else
                                    for $language in $languages
                                        let $label := mods-common:get-language-label($language)
                                        let $label := 
                                            if ($label eq $language) 
                                            then ()
                                            else
                                                if ($label)
                                                then concat(' (', $label, ')') 
                                                else ()
                                        order by upper-case($language) ascending
                                        return
                                            <li><a href="?filter=Language&amp;value={replace($language, '-', '')}&amp;query-tabs=advanced-search-form&amp;default-operator=and&amp;collection={$local:SEARCH-COLLECTION//collection}">{$language}{$label}</a></li>
                     }
                     </ul>
                 else
                     if ($type eq 'genre')
                     then 
                         <ul>
                         {
                            let $genres := distinct-values($cached/(mods:genre))
                            let $genres-count := count($genres)
                            return
                                if ($genres-count gt $local:MAX_RESULTS_SUBJECTS)
                                then
                                    <li>There are too many genres ({$genres-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RESULTS_SUBJECTS}.</li>
                                else
                                    if ($record-count gt $local:MAX_RECORD_COUNT)
                                    then
                                        <li>There are too many records ({$record-count}) to process without overloading the server. Please restrict the result set by performing a narrower search. The maximum number is {$local:MAX_RECORD_COUNT}.</li>
                                    else
                                        for $genre in $genres
                                            let $label-1 := doc(concat($config:edit-app-root, '/code-tables/genre-local-codes.xml'))/*:code-table/*:items/*:item[*:value eq $genre]/*:label
                                            let $label-2 := doc(concat($config:edit-app-root, '/code-tables/genre-marcgt-codes.xml'))/*:code-table/*:items/*:item[*:value eq $genre]/*:label
                                            let $label := 
                                                if ($label-1)
                                                then $label-1
                                                else 
                                                    if ($label-2)
                                                    then $label-2
                                                    else $genre
                                            let $label := 
                                                if ($label eq $genre) 
                                                then ()
                                                else
                                                    if ($label)
                                                    then concat(' (', $label, ')') 
                                                    else ()
                                            order by upper-case($genre) ascending
                                            return
                                                <li><a href="?filter=Genre&amp;value={$genre}&amp;query-tabs=advanced-search-form&amp;default-operator=and&amp;collection={$local:SEARCH-COLLECTION//collection}">{$genre}{$label}</a></li>
                         }
                         </ul>
                 else
                     if ($type eq 'keywords')
                     then local:keywords($cached, $record-count)
                     else ()
                 