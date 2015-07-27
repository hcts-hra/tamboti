xquery version "3.0";

import module namespace functx = "http://www.functx.com";
import module namespace mods-hra-framework="http://hra.uni-heidelberg.de/ns/mods-hra-framework" at "mods-hra.xqm";
import module namespace mods-common="http://exist-db.org/mods/common" at "/db/apps/tamboti/modules/mods-common.xql";

declare namespace ext="http://exist-db.org/mods/extension";
declare namespace json="http://www.json.org";
declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";
declare namespace xhtml="http://www.w3.org/1999/xhtml";
declare namespace xlink="http://www.w3.org/1999/xlink";

(:declare option exist:serialize "method=json media-type=text/javascript";:)

declare function local:format-list-view($entry as element(mods:mods), $collection-short as xs:string) as element(span) {
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
                if (string($names-primary)) then
                    (
                        mods-common:format-multiple-names($names-primary, 'list-first', $global-transliteration, $global-language)
                    ,
                    '. '
                    )
                else 
                    ()
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
        if (not($entry/mods:name/mods:role/mods:roleTerm[not(lower-case(.) = $mods-hra-framework:primary-roles)]))   then
            if (not($entry/mods:relatedItem[@type eq 'host'])) then
                ''
            else 
                '.'
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
            '.'
        )
    
    let $result := <span xmlns="http://www.w3.org/1999/xhtml" class="record">{$result}</span>
    let $result := mods-common:clean-up-punctuation($result)
    return $result
};

(: return a deep copy of the elements and attributes without ANY namespaces :)
declare function local:remove-namespaces($element as element()) as element() {
     element { local-name($element) } {
         for $att in $element/@*
         return
             attribute {local-name($att)} {$att},
         for $child in $element/node()
         return
             if ($child instance of element())
             then local:remove-namespaces($child)
             else $child
         }
};

declare function local:filter-family-name-starting($entries, $starting-char) {
    for $entry in $entries[starts-with(data(.//mods:mods/mods:name/mods:namePart[@type="family"]), $starting-char)]
    let $name-entity := $entry//mods:mods/mods:name[@type="personal" and mods:namePart/@type="family" and starts-with(data(.), $starting-char)]
    let $name-family := data($name-entity[1]/mods:namePart[@type="family"])
    order by $name-family
    return
        $entry
};

declare function local:filter-by-agent-name($entries, $familyName, $givenName) {
    let $entries :=
        if ($familyName) then 
            $entries[./mods:mods/mods:name/mods:namePart[@type="family"] = $familyName]
        else
            $entries
    let $entries :=
        if ($givenName) then 
            $entries[./mods:mods/mods:name/mods:namePart[@type="given"] = $givenName]
        else
            $entries
    return $entries
};


declare function local:filter-by-year($entries, $year) {
    $entries[
            ./mods:mods/mods:originInfo/mods:dateIssued[contains(., $year)]
            or .//mods:originInfo/mods:dateCreated[contains(., $year)]
            or .//mods:relatedItem/mods:originInfo/mods:dateCreated[contains(., $year)]
            or .//mods:relatedItem/mods:originInfo/mods:dateIssued[contains(., $year)]
            ]
};

declare function local:filter-by-genre($entries, $genre) {
    $entries[./mods:mods/mods:genre[@authority="local"]/string() = $genre]
};

declare function local:order-by($entries, $order-by, $desc) {
    switch ($order-by)
        case "year" return
            if ($desc) then
                for $entry in $entries
                let $year := distinct-values( 
                    ( 
                        functx:substring-before-if-contains(data($entry/mods:mods/mods:originInfo/mods:dateIssued[1]), "-"),
                        functx:substring-before-if-contains(data($entry/mods:mods/mods:originInfo/mods:dateCreated[1]), "-"),
                        functx:substring-before-if-contains(data($entry//mods:relatedItem/mods:originInfo/mods:dateCreated[1]), "-"),
                        functx:substring-before-if-contains(data($entry//mods:relatedItem/mods:originInfo/mods:dateIssued[1]), "-")
                    )
                )[1]
                order by
                    $year
                    descending
                return
                    $entry
            else
                for $entry in $entries
                let $year := distinct-values( 
                    ( 
                        functx:substring-before-if-contains(data($entry/mods:mods/mods:originInfo/mods:dateIssued[1]), "-"),
                        functx:substring-before-if-contains(data($entry/mods:mods/mods:originInfo/mods:dateCreated[1]), "-"),
                        functx:substring-before-if-contains(data($entry//mods:relatedItem/mods:originInfo/mods:dateCreated[1]), "-"),
                        functx:substring-before-if-contains(data($entry//mods:relatedItem/mods:originInfo/mods:dateIssued[1]), "-")
                    )
                )
                order by
                    $year[1]
                return
                    $entry

        case "title" return
            if ($desc) then
                for $entry in $entries
                order by 
                    string-join($entry/mods:mods/mods:titleInfo/mods:title, ". ")
                    descending
                return 
                    $entry
            else
                for $entry in $entries
                order by 
                    string-join($entry/mods:mods/mods:titleInfo/mods:title, ". ")
                return 
                    $entry

        default return
            for $entry in $entries
            let $year := distinct-values( 
                ( 
                    functx:substring-before-if-contains(data($entry/mods:mods/mods:originInfo/mods:dateIssued[1]), "-"),
                    functx:substring-before-if-contains(data($entry/mods:mods/mods:dateCreated[1]), "-"),
                    functx:substring-before-if-contains(data($entry//mods:relatedItem/mods:originInfo/mods:dateCreated[1]), "-")
                )
            )[1]
            order by 
                $year
                descending
            return
                $entry
};


let $collection := xmldb:encode-uri(request:get-parameter("collection", "/db/data/commons/Cluster Publications"))
let $output-type := request:get-parameter("output", "")
let $uuid := request:get-parameter("uuid", "")
let $action := request:get-parameter("action", "")
let $cors := response:set-header("Access-Control-Allow-Origin", "*")
let $family-name-starting-char := request:get-parameter("familyNameStartingWith", "")

let $result :=
    switch ($action)
        case "singleEntry" return 
            let $entry := collection($collection)/mods:mods[@ID=$uuid]
            return
                switch ($output-type)
                    case "mods" return
                        <xml>
                            {
                                $entry
                            }
                        </xml>
                    default return
(:                        let $html := mods-common:title-full($entry/mods:titleInfo):)
                        let $html := functx:change-element-ns-deep(local:format-list-view($entry, $collection), '', '')
                        return 
                            $html
                            
        case "distinctFamilyNames" return
            let $givenName := request:get-parameter("givenName", "")
            let $names :=
                if ($givenName) then
                    distinct-values(
                        collection($collection)//mods:mods/mods:name[./mods:namePart[@type="given"]/string() = $givenName]/mods:namePart[@type="family"])
                else
                    if ($family-name-starting-char) then
                        distinct-values(collection($collection)//mods:mods/mods:name/mods:namePart[@type="family" and starts-with(data(.), $family-name-starting-char)]/string())
                    else
                        distinct-values(collection($collection)//mods:mods/mods:name/mods:namePart[@type="family"]/string())

            return
                <names>
                    {
                        for $name in $names
                            order by $name
                            ascending
                            return
                                if($name) then
                                    <name json:array="true">{$name}</name>
                                else
                                    ()
                    }
                </names>
                
        case "distinctGivenNames" return
            let $familyName := request:get-parameter("familyName", "")
            let $names := 
                if ($familyName) then
                    distinct-values(collection($collection)//mods:mods/mods:name[./mods:namePart[@type="family"]/string() = $familyName]/mods:namePart[@type="given"])
                else 
                    if ($family-name-starting-char) then
                        distinct-values(collection($collection)//mods:mods/mods:name[starts-with(./mods:namePart[@type="family"]/string(), $family-name-starting-char) ]/mods:namePart[@type="given"]/string())
                    
                else
                        distinct-values(collection($collection)//mods:mods/mods:name/mods:namePart[@type="given"])
                    
            return
                <names>
                    {
                        for $name in $names
                            order by $name
                            ascending
                            return
                                if($name) then
                                    <name json:array="true">{$name}</name>
                                else
                                    ()
                    }
                </names>

        default 
            return
                let $start := xs:integer(request:get-parameter("start", 1))
                let $limit := xs:integer(request:get-parameter("limit", 20))
                let $order-by := request:get-parameter("orderBy", "year")
                let $desc := request:get-parameter("desc", "true")
                let $filter-by-year := request:get-parameter("filterByYear", "")
                let $filter-by-genre := request:get-parameter("filterByGenre", "")
                let $filter-by-familyName := request:get-parameter("filterByFamilyName", "")
                let $filter-by-givenName := request:get-parameter("filterByGivenName", "")
                
                let $entries := collection($collection)[./mods:mods]
                
                let $distinct-years := distinct-values(
                    for $date in distinct-values((
                                        $entries/mods:mods/mods:originInfo/mods:dateIssued,
                                        $entries/mods:mods/mods:originInfo/mods:dateCreated,
                                        $entries//mods:relatedItem/mods:originInfo/mods:dateCreated,
                                        $entries//mods:relatedItem/mods:originInfo/mods:dateIssued
                                    ))
                        let $year :=  functx:get-matches($date, "[0-9][0-9][0-9][0-9]*")[1]
                        order by 
                            $year
                            descending
                        return 
                            $year
                        )
                
                let $distinct-genres := distinct-values($entries/mods:mods/mods:genre[@authority="local"]/string())
                
                (: filter:)
                let $entries := 
                    if ($family-name-starting-char) then 
                        local:filter-family-name-starting($entries, $family-name-starting-char)
                    else
                        $entries

                let $entries := 
                    if ($filter-by-year) then 
                        local:filter-by-year($entries, $filter-by-year)
                    else
                        $entries
                
                let $entries :=
                    if ($filter-by-genre) then
                        local:filter-by-genre($entries, $filter-by-genre)
                    else
                        $entries
                        
                let $entries := 
                    if ($filter-by-familyName or $filter-by-givenName) then 
                        local:filter-by-agent-name($entries, $filter-by-familyName, $filter-by-givenName)
                    else
                        $entries
                
                        
                
                let $count := count($entries)
                
                (: order result :)
                let $entries := local:order-by($entries, $order-by, $desc)
                (: Limit :)
                let $entries := 
                    if ($limit != 0) then 
                        $entries[position() >= $start and position() < $start + $limit]
                    else
                        $entries
                
                let $result :=
                    <root>
                        <count>{$count}</count>
                            {
                                for $year in $distinct-years
                                return
                                    <distinctYears json:array="true">{$year}</distinctYears>
                            }
                
                            {
                                for $genre in $distinct-genres
                                order by lower-case($genre)
                                return
                                    <distinctGenres json:array="true">{$genre}</distinctGenres>
                            }
                        <start>{$start}</start>
                        <limit>{$limit}</limit>
                        {
                            for $entry in $entries
                                let $authors := $entry/mods:mods/mods:name[@type="personal"]
                                let $uuid := $entry/mods:mods/@ID/string()
                                let $year := distinct-values(
                                    (
                                        functx:substring-before-if-contains(data($entry//mods:mods/mods:originInfo/mods:dateIssued[1]), "-"),
                                        functx:substring-before-if-contains(data($entry//mods:originInfo/mods:dateCreated[1]), "-"),
                                        functx:substring-before-if-contains(data($entry//mods:relatedItem/mods:originInfo/mods:dateCreated[1]), "-"),
                                        functx:substring-before-if-contains(data($entry//mods:relatedItem/mods:originInfo/mods:dateIssued[1]), "-")
                                    )
                                )[1]

                                return
                                    <entries json:array="true">
                                        <dc>{$entry//mods:relatedItem/mods:originInfo/mods:dateCreated}</dc>
                                        <uuid>{$uuid}</uuid>
                                        <genre>{$entry/mods:mods/mods:genre[@authority="local"]/string()}</genre>
                                        {
                                            for $author in $authors
                                                let $role := $author/mods:role/mods:roleTerm[@type="code" and @authority="marcrelator"]/string()
                                                let $author-name-string:=
                                                    if($author/mods:namePart[@type="family"]) then
                                                        $author/mods:namePart[@type="family"]/string() || ", " || $author/mods:namePart[@type="given"]/string()
                                                    else
                                                        $author/mods:namePart/string()
                                                where not(empty($author/mods:namePart/text()))
                                                order by $author-name-string
                                                return
                                                    <person json:array="true">
                                                        {
                                                            for $famName in $author/mods:namePart[@type="family"]
                                                            return
                                                                <familyName>{$famName}</familyName>
                                                        }
                                                        {
                                                            for $givenName in $author/mods:namePart[@type="given"]
                                                            return
                                                                <givenName>{$givenName}</givenName>
                                                        }
                                                        <fullName>
                                                            {$author-name-string}
                                                        </fullName>
                                                        <role>
                                                            {$role}
                                                        </role>
                                                    </person>
                                        }
                                        <title>{string-join($entry/mods:mods/mods:titleInfo/mods:title, ". ")}</title>
                                        <year>{$year}</year>
                                        {
                                            for $relItem in $entry/mods:mods/mods:relatedItem
                                            return
                                                <relatedItem json:array="true">
                                                    <type>{$relItem/@type/string()}</type>
                                                    <xlink>{$relItem/@xlink:href/string()}</xlink>
                                                    {
                                                        if (starts-with($relItem/@xlink:href/string(), "#w_") or starts-with($relItem/@xlink:href/string(), "w_")) then
                                                            let $tamboti-work-uuid := functx:substring-after-if-contains($relItem/@xlink:href/string(), "#")
                                                            let $tamboti-image-uuid := collection("/db/data/")//vra:work[@id=$tamboti-work-uuid]/vra:relationSet/vra:relation[@type="imageIs" and @pref="true"][1]/@relids/string()
                                                            return
                                                                <tambotiImageUuid>
                                                                    {
                                                                        $tamboti-image-uuid
                                                                    }
                                                                </tambotiImageUuid>
                                                        else
                                                            ()
                                                    }
                                                </relatedItem>
                                        }
                                        <locationURL>
                                            {
                                                let $location := $entry/mods:mods/mods:location/mods:url[@usage="primary display"][1]
                                                return
                                                    (
                                                    <url>{$location/string()}</url>,
                                                    <lastAccess>{data($location/@dateLastAccessed)}</lastAccess>
                                                    )
                                                
                                            }
                                        </locationURL>
                                    </entries>
                        }
                    </root>
                return $result    
return
    switch ($output-type)
        case "xml" return
            $result
        case "html" return
            $result
        default return
            util:serialize($result, "method=json media-type=text/javascript")
