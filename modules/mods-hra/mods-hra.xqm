xquery version "3.1";

module namespace mods-hra = "http://hra.uni-heidelberg.de/ns/tamboti/mods-hra/";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace mads = "http://www.loc.gov/mads/v2";
declare namespace mods-editor = "http://hra.uni-heidelberg.de/ns/mods-editor/";
declare namespace ext = "http://exist-db.org/mods/extension";

declare variable $mods-hra:author-roles := ('aut', 'author', 'cre', 'creator', 'composer', 'cmp', 'artist', 'art', 'director', 'drt', 'photographer', 'pht');
declare variable $mods-hra:eastern-languages := ('chi', 'jpn', 'kor', 'skt', 'tib');
declare variable $mods-hra:primary-roles := (
    'artist', 'art', 
    'author', 'aut', 
    'composer', 'cmp', 
    'correspondent', 'crp', 
    'creator', 'cre', 
    'director', 'drt', 
    'photographer', 'pht', 
    'reporter', 'rpt')
;
declare variable $mods-hra:given-name-last-languages := ('chi', 'jpn', 'kor', 'vie'); 

(:~
: The <b>mods-common:get-short-title</b> function returns 
: a compact title for list view, for subject in detail view, and for related items in list and detail view.
: The function seeks to approach the Chicago style.
:
: @author Wolfgang M. Meier
: @author Jens Østergaard Petersen
: @see http://www.loc.gov/standards/mods/userguide/titleinfo.html
: @see http://www.loc.gov/standards/mods/userguide/relateditem.html
: @see http://www.loc.gov/standards/mods/userguide/subject.html#titleinfo
: @param $entry The MODS entry as a whole or a relatedItem element
: @return The titleInfo formatted as XHTML.
:)
declare function mods-hra:get-short-title($resource as element()) {
    (: If the entry has a related item of @type host with an extent in part, it is a periodical article or a contribution to an edited volume and the title should be enclosed in quotation marks. :)
    (: In order to avoid having to iterate through the (extremely rare) instances of multiple elements and in order to guard against cardinality errors in faulty records duplicating elements that are supposed to be unique, a lot of filtering for first child is performed. :)
    
    (: The short title only consists of the main title, which is untyped, and its renditions in transliteration and translation. 
    Filter away the remaining titleInfo @type values. 
    This means that a record without an untyped titleInfo will not display any title. :)
    let $titleInfo := $resource/mods:titleInfo[not(@type = ('abbreviated', 'uniform', 'alternative'))]
    
    (: The main title can be 1) in original language and script, or 2) in transliteration, or 3) in translation. 
    Therefore, split titleInfo into these three, reusing $titleInfo for the untyped titleInfo. 
    Since "transliterated" is not a valid value for @type, we have to deduce the existence of a transliterated titleInfo from the fact that it contains @transliteration. 
    Since the Tamboti editor operates with a global setting for transliteration (in extension), 
    it is necessary to mark a transliterated titleInfo in the instances by means of an empty @transliteration. 
    Since in MODS, a transliterated titleInfo has the @type value "translated", we check for this as well. 
    Hence a titleInfo with @type "translated" with be a translation if it has no @transliteration (empty or not); otherwise it will be a transliteration.
    A translated titleInfo ought to have a @lang, but it is not necessary to check for this. :)
    (: NB: Parsing this would be a lot easier if MODS accepted "transliterated" as value for @type on titleInfo. :)
    (: NB: With 3.5 MODS accepts "transliterated" as value for @otherType on titleInfo. :)
    let $titleInfo-transliterated := $titleInfo[@transliteration][@type eq 'translated'][1]
    let $titleInfo-translated := $titleInfo[not(@transliteration)][@type eq 'translated'][1]
    let $titleInfo := $titleInfo[not(@type)][1]
    
    (: Split each of the three forms into their components. :)
    let $nonSort := $titleInfo/mods:nonSort[1]
    let $title := $titleInfo/mods:title[1]
    let $subTitle := $titleInfo/mods:subTitle[1]
    let $partNumber := $titleInfo/mods:partNumber[1]
    let $partName := $titleInfo/mods:partName[1]
    
    let $nonSort-transliterated := $titleInfo-transliterated/mods:nonSort[1]
    let $title-transliterated := $titleInfo-transliterated/mods:title[1]
    let $subTitle-transliterated := $titleInfo-transliterated/mods:subTitle[1]
    let $partNumber-transliterated := $titleInfo-transliterated/mods:partNumber[1]
    let $partName-transliterated := $titleInfo-transliterated/mods:partName[1]

    let $nonSort-translated := $titleInfo-translated/mods:nonSort[1]
    let $title-translated := $titleInfo-translated/mods:title[1]
    let $subTitle-translated := $titleInfo-translated/mods:subTitle[1]
    let $partNumber-translated := $titleInfo-translated/mods:partNumber[1]
    let $partName-translated := $titleInfo-translated/mods:partName[1]
        
    (: Format each of the three kinds of titleInfo. :)
    let $title-formatted := 
        concat(
        if (string($nonSort))
        (: NB: This assumes that nonSort is not used in Asian scripts; otherwise we would have to avoid the space by checking the language. :)
        then concat($nonSort, ' ' , $title)
        else $title
        , 
        if (string($subTitle)) 
        then concat(': ', $subTitle)
        else ()
        ,
        if (string($partNumber) or string($partName))
        then
            if (string($partNumber) and string($partName)) 
            then concat('. ', $partNumber, ': ', $partName)
            else
                if (string($partNumber))
                then concat('. ', $partNumber)
                else concat('. ', $partName)
                    
        else ()
        )
    
    let $title-transliterated-formatted := 
        (
        if (string($nonSort-transliterated)) 
        then concat($nonSort-transliterated, ' ' , $title-transliterated)
        else $title-transliterated
        , 
        if (string($subTitle-transliterated)) 
        then concat(': ', $subTitle-transliterated)
        else ()
        ,
        if (string($partNumber-transliterated) or string($partName-transliterated))
        then
            if (string($partNumber-transliterated) and string($partName-transliterated)) 
            then concat('. ', $partNumber-transliterated, ': ', $partName-transliterated)
            else
                if (string($partNumber-transliterated))
                then concat('. ', $partNumber-transliterated)
                else concat('. ', $partName-transliterated)
        else ()
        )    
    let $title-transliterated-formatted := string-join($title-transliterated-formatted, '')
    
    let $title-translated-formatted := 
        (
            if (string($nonSort-translated)) 
            then concat($nonSort-translated, ' ' , $title-translated)
            else $title-translated
            , 
            if (string($subTitle-translated)) 
            then concat(': ', $subTitle-translated)
            else ()
            ,
            if (string($partNumber-translated) or string($partName-translated))
            then
                if (string($partNumber-translated) and string($partName-translated)) 
                then concat('. ', $partNumber-translated, ': ', $partName-translated)
                else
                    if (string($partNumber-translated))
                    then concat('. ', $partNumber-translated)
                    else concat('. ', $partName-translated)
            else ()
        )
    let $title-translated-formatted := string-join($title-translated-formatted, '')
    
    (: Assemble the full short title to display. :)
    let $title :=
        ( 
        if ($title-transliterated)
        (: It is standard (at least in Sinology and Japanology) to first render the transliterated title, then the title in native script. :)
        then (<span xmlns="http://www.w3.org/1999/xhtml" class="title">{$title-transliterated-formatted}</span>, ' ')
        else ()
        , 
        if ($title-transliterated)
        (: If there is a transliterated title, the title in original script should not be italicised. :)
        then <span xmlns="http://www.w3.org/1999/xhtml" class="title-no-italics">{$title-formatted}</span>
        else
        (: If there is no transliterated title, the standard for Western literature. :)
            if (exists($resource/mods:relatedItem[@type eq 'host'][1]/mods:part/mods:extent) 
               or exists($resource/mods:relatedItem[@type eq 'host'][1]/mods:part/mods:detail/mods:number))
           then <span xmlns="http://www.w3.org/1999/xhtml" class="title-no-italics">“{$title-formatted}”</span>
           else <span xmlns="http://www.w3.org/1999/xhtml" class="title">{$title-formatted}</span>
        ,
        if ($title-translated)
        (: Enclose the translated title in parentheses. Titles of @type "translated" are always made by the cataloguer. 
        If a title is translated on the title page, it is recorded in a titleInfo of @type "alternative". :)
        then <span xmlns="http://www.w3.org/1999/xhtml" class="title-no-italics"> ({$title-translated-formatted})</span>
        else ()
        )
        
    let $title := 
        if ($title != '')
        then serialize($title, map {"method": "xml"})
        else "<no title information>"    
    
    return $title
};

declare function mods-hra:get-author($resource) {
    let $mods-name := $resource/mods:name[mods:role/mods:roleTerm = $mods-hra:author-roles or not(mods:role/mods:roleTerm)][1] 
    (: Sort according to family and given names.:)
    let $mods-sortFirst :=
        (: If there is a namePart marked as being in a Western language, there could in addition be a transliterated and a Eastern-script "nick-name", but the Western namePart should have precedence over the nick-name, therefore pick out the Western-language nameParts first. :)
        if ($mods-name/mods:namePart[@lang != $mods-hra:eastern-languages]/text())
        then
           (: If it has a family type, take it; otherwise take whatever namePart there is (in case of a name which has not been analysed into given and family names. :)
           if ($mods-name/mods:namePart[@type eq 'family']/text())
           then $mods-name/mods:namePart[@lang != $mods-hra:eastern-languages][@type eq 'family'][1]/text()
           else $mods-name/mods:namePart[@lang != $mods-hra:eastern-languages][1]/text()
        else
           (: If there is not a Western-language namePart, check if there is a namePart with transliteration; if this is the case, take it. :)
           if ($mods-name/mods:namePart[@transliteration]/text())
           then
               (: If it has a family type, take it; otherwise take whatever transliterated namePart there is. :)
               if ($mods-name/mods:namePart[@type eq 'family']/text())
               then $mods-name/mods:namePart[@type eq 'family'][@transliteration][1]/text()
               else $mods-name/mods:namePart[@transliteration][1]/text()
           else
               (: If the name does not have a transliterated namePart, it is probably a "standard" (unmarked) Western name, if it does not have a script attribute or uses Latin script. :)
               if ($mods-name/mods:namePart[@script eq 'Latn']/text() or $mods-name/mods:namePart[not(@script)]/text())
               then
               (: If it has a family type, take it; otherwise takes whatever untransliterated namePart there is.:) 
                   if ($mods-name/mods:namePart[@type eq 'family']/text())
                   then $mods-name/mods:namePart[not(@script) or @script eq 'Latn'][@type eq 'family'][1]/text()
                   else $mods-name/mods:namePart[not(@script) or @script eq 'Latn'][1]/text()
               (: The last step should take care of Eastern names without transliteration. These will usually have a script attribute :)
               else
                   if ($mods-name/mods:namePart[@type eq 'family']/text())
                   then $mods-name/mods:namePart[@type eq 'family'][1]/text()
                   else $mods-name/mods:namePart[1]/text()
    let $mods-sortLast :=
        if ($mods-name/mods:namePart[@lang != $mods-hra:eastern-languages]/text())
        then $mods-name/mods:namePart[@lang != $mods-hra:eastern-languages][@type eq 'given'][1]/text()
        else
           if ($mods-name/mods:namePart[@transliteration]/text())
           then $mods-name/mods:namePart[@type eq 'given'][@transliteration][1]/text()
           else
               if ($mods-name/mods:namePart[@script eq 'Latn']/text() or $mods-name/mods:namePart[not(@script)]/text())
               then $mods-name/mods:namePart[@type eq 'given'][not(@script) or @script eq 'Latn'][1]/text()
               else $mods-name/mods:namePart[@type eq 'given'][1]/text()
    
    return string-join(($mods-sortFirst, $mods-sortLast), " ")    
};

declare function mods-hra:get-year($resource) as xs:string? {
        (:NB: year is sorted as string.:)
        if ($resource/mods:originInfo[1]/mods:dateIssued[1]) 
        then replace($resource/mods:originInfo[1]/mods:dateIssued[1], "-.*", "") 
        else 
            if ($resource/mods:originInfo[1]/mods:copyrightDate[1]) 
            then substring-before($resource/mods:originInfo[1]/mods:copyrightDate[1],'-') 
            else
                if ($resource/mods:originInfo[1]/mods:dateCreated[1]) 
                then substring-before($resource/mods:originInfo[1]/mods:dateCreated[1],'-') 
                else
                    if ($resource/mods:relatedItem[1]/mods:originInfo[1]/mods:dateIssued[1]) 
                    then substring-before($resource/mods:relatedItem[1]/mods:originInfo[1]/mods:dateIssued[1],'-') 
                    else
                        if ($resource/mods:relatedItem[1]/mods:originInfo[1]/mods:copyrightDate[1]) 
                        then substring-before($resource/mods:relatedItem[1]/mods:originInfo[1]/mods:copyrightDate[1],'-') 
                        else
                            if ($resource/mods:relatedItem[1]/mods:originInfo[1]/mods:dateCreated[1]) 
                            then substring-before($resource/mods:relatedItem[1]/mods:originInfo[1]/mods:dateCreated[1],'-') 
                            else
                                if ($resource/mods:relatedItem[1]/mods:part[1]/mods:date[1]) 
                                then substring-before($resource/mods:relatedItem[1]/mods:part[1]/mods:date[1],'-') 
                                else ()
};

declare function mods-hra:get-names($resource) {
    let $global-transliteration := $resource/mods:extension/ext:transliterationOfResource/text()
    let $global-language := $resource/mods:language[1]/mods:languageTerm[1]/text()
    let $names := $resource/mods:name
    let $names-primary := $names[@type = ('personal', 'corporate', 'family') or not(@type)][(mods:role/mods:roleTerm[lower-case(.) = $mods-hra:primary-roles]) or empty(mods:role/mods:roleTerm)]
        
    return
        let $names :=
            for $name at $position in $names-primary
            
            return mods-hra:retrieve-name($name, $position, 'list-first', $global-transliteration, $global-language)
        let $nameCount := count($names)
        let $formatted :=
            if ($nameCount gt 0) 
            then mods-hra:serialize-list($names, $nameCount)
            else ()
            
        return normalize-space($formatted)            
};

declare function mods-hra:retrieve-name($name as element(), $position as xs:int, $destination as xs:string, $global-transliteration as xs:string?, $global-language as xs:string?) {    
    let $mods-name := try {mods-hra:format-name($name, $position, $destination, $global-transliteration, $global-language)} catch * {()}
    let $mods-name := $mods-name/spans
    let $mads-reference := replace($name/@xlink:href, '^#?(.*)$', '$1')
    
    return
        if ($mads-reference)
        then
            let $mads-record :=
                if (empty($mads-reference)) 
                then ()        
                else collection($config:mads-collection)/mads:mads[@ID eq $mads-reference]/mads:authority
            let $mads-preferred-name :=
                if (empty($mads-record)) 
                then ()
                else mods-hra:format-name($mads-record/mads:name, 1, $destination, $global-transliteration, $global-language)
            let $mads-preferred-name-display :=
                if (empty($mads-preferred-name))
                then ()
                else concat(' (', $mads-preferred-name,')')
            return
                if ($mads-preferred-name eq $mods-name)
                then $mods-name
                else concat($mods-name, $mads-preferred-name-display)
        else $mods-name
};

declare function mods-hra:serialize-list($sequence as item()+, $sequence-count as xs:integer) as xs:string {       
    if ($sequence-count eq 1)
        then $sequence
        else
            if ($sequence-count eq 2)
            then concat(
                subsequence($sequence, 1, $sequence-count - 1),
                (:Places " and " before last item.:)
                ' and ',
                $sequence[$sequence-count]
                )
            else concat(
                (:Places ", " after all items that do not come last.:)
                string-join(subsequence($sequence, 1, $sequence-count - 1)
                , ', ')
                ,
                (:Places ", and " before item that comes last.:)
                ', and ',
                $sequence[$sequence-count]
                )
};

declare function mods-hra:format-name($name as element()?, $position as xs:integer, $destination as xs:string, $global-transliteration as xs:string?, $global-language as xs:string?) {  
    (: Get the type of the name, personal, corporate, conference, or family. :)
    (:NB: why read @lang from name and not namePart?:)
    let $name-language := $name/@lang
    let $name-type := $name/@type
    let $description := $name//mods:description
    
    return   
    (: If the name is of type conference, do nothing, since get-conference-detail-view and get-conference-hitlist take care of conference. 
        The name of a conference does not occur in the same positions as the other name types.:)
        if ($name-type eq 'conference')
        then ()
        else
            (: If the name is of type corporate, i.e. if we are dealing with an institution, there is also not much we can do, 
            but we assume that the sequence of name parts is meaningfully constructed, that is, that the terms are ordered in a general to specific sequence,
            and we just string-join the different parts, dividing them with a comma. :)
            (: If a family as such is responsible for a publication, we must assume that all name parts will describe the family name.
            so just string-join any name parts, dividing them with a comma. :)
            (: This is the same as type corporate, so the two are here merged. :)
            (: A type-less name is also treated here. :)
            (: NB: One could also decide to treat a type-less name as a personal name, since there are most of these. :)
            if ($name-type = ('corporate', 'family', '')) 
            then
                let $advanced-search-data :=
                    <data>
                        <collection>{$config:data-collection-name}</collection>
                        <field1>Name</field1>
                        <input1>{string-join($name/mods:namePart[. != ''], ' ')}</input1>
                        <default-operator>and</default-operator>
                    </data>                

                return
                <span>
                    <spans class="name">{
                        concat(
                        string-join(
                            for $item in $name/mods:namePart[. != '']
                            where string($item/@transliteration) 
                            
                            return $item
                        , ', ')
                        
                        , ' ', 
                        string-join(
                            for $item in $name/mods:namePart[. != '']
                            where not(string($item/@transliteration))
                            
                            return $item
                        , ', ')
                        )
                    }</spans>
                    <a class="name-link" onclick="tamboti.apis.advancedSearchWithData({$advanced-search-data})" href="#" title="Find all records with the same name">
                        (find all records)
                    </a>
                </span>
            else
                    (: Split up the name parts into three groups: 
                    1. Basic: name parts which do not have a transliteration attribute and that do not have a script attribute 
                    (or that are in Latin script).
                    2. Transliteration: those name parts which have transliteration and do not have a script attribute (or that have Latin script, 
                    which all transliterations implicitly have).
                    3. Script: name parts which do not have a transliteration attribute, 
                    but have a script attribute (but are not in Latin script, which characterises transliterations). :)
                    (: NB: The assumption is that transliteration is always into Latin script, but - obviously - it may e.g. be in Cyrillic script. :)
                    (: If the above three name groups all occur, they should be formatted in the sequence of 1, 2, and 3. 
                    Only in rare cases will 1, 2, and 3 occur all together,
                    for instance a Westerner with a name form in Chinese characters or a Chinese 
                    with an established Western-style name form different from the transliterated name form. 
                    In the case of persons that use Latin script to render their name, only 1 will be used. Here we have typical Western names,
                    but also the names of Chinese and Japanese, if the names occur in Westrn name order.
                    In the case of e.g. Chinese or Russian names, only 2 and 3 will be used. 
                    Only 3 will be used if no transliteration is given, but only the name in non-Western script.
                    Only 2 will be used if only a transliteration is given. :)
                    (: When formatting a name, $position in a sequence of names is relevant to the formatting of Basic, 
                    i.e. to Western names, and to Russian names in Script and Transliteration. 
                    Hungarian is special, in that it uses Latin script, but has the name order family-given. :)
                    
                    (: When formatting a name, the first question to ask is whether the name parts are typed, 
                    i.e. whether they are divded into given and family name parts (plus date and terms of address). 
                    If they are not, there is really not much one can do, 
                    besides concatenating the name parts and trusting that their sequence is meaningful. :)
                    (: NB: If the name is translated from one language to another (e.g. William the Conqueror, 
                    Guillaume le Conquérant), there will be two $name-basic, one for each language. This is not handled. :)
                    (: NB: If the name is transliterated in two ways, there will be two $name-in-transliteration, 
                    one for each transliteration scheme. This is not handled. :)
                    (: NB: If the name is rendered in two scripts, there will be two $name-in-non-latin-script, 
                    one for each script. This is not handled. :)
                    
                    let $name-contains-transliteration :=                           
                        (: We allow the transliteration attribute to be on name itself. 
                        We allow it to be empty, because we use it with $global-transliteration to signal 
                        that a name or namePart is transliterated or contains transliteration.:)
                        if (($name[*:namePart[@transliteration]] or $name[@transliteration]))
                        then true()
                        else
                            (: If the record as a whole is marked as having transliteration, we use this instead, 
                            even though no transliteration attribute is present on any name or name part.:)
                            (:NB: this does ot seem t be needed.:)
                            if ($global-transliteration)
                            then true()
                            else false()
                    (:let $log := util:log("DEBUG", ("##$name-contains-transliteration): ", $name-contains-transliteration)):)
                    
                    (: If the name does not contain a name part with a transliteration attribute, then it is a basic name, 
                    i.e. a name where a distinction between the name in a native script and in a transliteration does not arise. 
                    Typical examples are Western names, but this also includes Eastern names where no effort has been taken to 
                    distinguish between native script and transliteration and which observe Western name order even though their
                    names are transcribed. Since many chose to do this, we should treat such names as Basic, even though they are
                    in fact transliterated (though often not according to standard transliteraiton schemes).
                    This mean that Transliteration cannot occur without Script (whereas Script can occur with Transliteration).
                    In order to catch cases  where Westerners have a Chinese name, possibly also transliterated,
                    we require that they have their original (Western) name set to one of the common European languages. :)
                    (: NB: The whole notion of names being in different languages is problematic. :)
                    (: NB: Only coded language terms are treated here. :)
                    (: Name parts of type date are excluded since they typically do not have language attributes; 
                    they are treated separately.:)
                    
                    let $name-basic :=
                        if (not($name-contains-transliteration))
                        
                        (:If no transliteration is used anywhere in the name, 
                        then we grab the name parts in which Western script is used or in which no script is set and in which
                        there is no transliteration attribute.
                        We do not want to have any non-Westerns names here: they will be picked up in $name-in-non-latin-script:) 
                        
                        then
                            <name>
                                {
                                    $name/mods:namePart
                                        [not(@type eq 'date')]
                                        [not(@transliteration)]
                                        [(not(string(@script)) or @script = ('Latn', 'latn', 'Latin'))]
                                }
                            </name>
                        
                        (:If transliteration is used somewhere in the name, then grab the parts that are untransliterated and that do not.:)
                        (:NB: Is $global-language relevant here?:)
                        else
                            <name>
                                {
                                    $name/mods:namePart
                                        [not(@type eq 'date')]
                                        [not(@lang = $mods-hra:given-name-last-languages)]
                                        (:NB: more language than English:)
                                        [not(string(@lang)) or @lang = 'eng']
                                        [not(@transliteration)]
                                }
                            </name>
                            
                        (:let $log := util:log("DEBUG", ("##$name-basic): ", $name-basic)):)
                    
                    (: If there is transliteration, there should be name parts with transliteration. 
                    To filter these, we seek name parts which contain the transliteration attribute, 
                    even though this may be empty 
                    (this is special to the templates, since they allow the user to set a global transliteration value, 
                    to be applied whereever an empty transliteration attribute occurs).:)
                    (: NB: Should English names be filtered away?:)
                    
                    let $name-in-transliteration := 
                        if ($name-contains-transliteration)
                        then 
                            <name>
                                {
                                    $name/mods:namePart[@transliteration]
                                }
                            </name>
                        else ()
                    (: If there is transliteration, the presumption must be that all name parts which are not transliterations 
                    (and which do not have the language set to a European language) are names in a non-Latin script. 
                    We filter for name parts which do no have the transliteration attribute or which have one with no contents, 
                    and which do not have script set to Latin, and which do not have English as their language. :)
                    
                    let $name-in-non-latin-script := 
                        if ($name-contains-transliteration)
                        then 
                            <name>
                                {
                                    $name/mods:namePart
                                        [not(@transliteration)]
                                        [(@script)]
                                        [not(@script = ('Latn', 'latn', 'Latin'))]
                                        [@lang = $mods-hra:given-name-last-languages]
                                }
                            </name>
                        else ()
                    (:let $log := util:log("DEBUG", ("##$name-in-non-latin-script): ", $name-in-non-latin-script)):)
                    
                    (:Switch around $name-in-non-latin-script and $name-basic if there is $name-in-transliteration. 
                    This is necessary because $name-in-non-latin-script looks like $name-basic in a record using global language.:) 
                    
                    let $name-in-non-latin-script1 := 
                        if (string($name-basic) and string($name-in-transliteration) and not(string($name-in-non-latin-script))) 
                        then $name-basic
                        else $name-in-non-latin-script
                    let $name-basic := 
                        if (string($name-basic) and string($name-in-transliteration) and not(string($name-in-non-latin-script)))
                        then ()
                        else $name-basic
                    let $name-in-non-latin-script := $name-in-non-latin-script1
                    
                    let $name-in-transliteration-link := string-join($name-in-transliteration/mods:namePart, ' ')
                    let $name-basic-link := string-join($name-basic/mods:namePart, ' ')
                    let $name-in-non-latin-script-link := string-join($name-in-non-latin-script/mods:namePart, ' ')
                    let $name-link := concat($name-basic-link, ' ' , $name-in-non-latin-script-link, ' ', $name-in-transliteration-link)  
                    let $advanced-search-data :=
                        <data>
                            <collection>{$config:data-collection-name}</collection>
                            <field1>Name</field1>
                            <input1>{normalize-space($name-link)}</input1>
                            <default-operator>and</default-operator>
                        </data>
                    
                    (: We assume that there is only one date name part in $name-basic. 
                    Date name parts with transliteration and script are rather theoretical. 
                    This date is attached at the end of the name, to distinguish between identical names. That is why it is set here, not below. :)
                    let $date-basic := $name-basic/mods:namePart[@type eq 'date']
                    
                    let $basic-name :=
                        (: ## 1 ##:)
                        if (string($name-basic))
                        (: If there are one or more name parts that are not marked as being transliteration and that are not marked as being in a certain script (aside from Latin). :)
                        then
                        (: Filter the name parts according to type. :)
                            let $family-name-basic := <name>{$name-basic/mods:namePart[@type eq 'family']}</name>
                            let $given-name-basic := <name>{$name-basic/mods:namePart[@type eq 'given']}</name>
                            let $termsOfAddress-basic := <name>{$name-basic/mods:namePart[@type eq 'termsOfAddress']}</name>
                            (:let $log := util:log("DEBUG", ("##$termsOfAddress-basic): ", $termsOfAddress-basic)):)

                            let $untyped-name-basic := <name>{$name-basic/mods:namePart[not(@type)]}</name>
                            (: $date-basic already has the date. :)
                            (: To get the name order, get the language of the namePart and send it to mods-common:get-name-order(), along with higher-level language values. :)
                            let $language-basic := 
                                if ($family-name-basic/mods:namePart/@lang)
                                then $family-name-basic/mods:namePart/@lang
                                else
                                    if ($given-name-basic/mods:namePart/@lang)
                                    then $given-name-basic/mods:namePart/@lang
                                    else
                                        if ($termsOfAddress-basic/mods:namePart/@lang)
                                        then $termsOfAddress-basic/mods:namePart/@lang
                                        else
                                            if ($untyped-name-basic/mods:namePart/@lang)
                                            then $untyped-name-basic/mods:namePart/@lang
                                            else ()
                            (:let $log := util:log("DEBUG", ("##$language-basic): ", $language-basic)):)
                            let $nameOrder-basic := mods-hra:get-name-order(distinct-values($language-basic), distinct-values($name-language), $global-language)
                            (:let $log := util:log("DEBUG", ("##$nameOrder-basic): ", $nameOrder-basic)):)
                                return
                                    if (string($untyped-name-basic))
                                    (: If there are name parts that are not typed, there is nothing we can do to order their sequence. 
                                    When name parts are not typed, it is generally because the whole name occurs in one name part, 
                                    pre-formatted for display (usually with a comma between family and given name), 
                                    but a name part may also be untyped when (non-Western) names that cannot (easily) be divided into family and given names are in evidence. 
                                    We trust that any sequence of untyped nameparts are meaningfully ordered and simply string-join them. :)
                                    then string-join($untyped-name-basic/mods:namePart, ' ') 
                                    else
                                    (: If the name parts are typed, we have a name divided into given and family name (and so on), 
                                    a name that is not a transliteration and that is not in a non-Latin script, i.e. an ordinary "Western" name. :)
                                        if ($position eq 1 and $destination eq 'list-first')
                                        (: If the name occurs first in author position in list view 
                                        and the name is not a name that occurs in family-given sequence (it is not an Oriental or a Hungarian name), 
                                        then format it with a comma and space between the family name and the given name, 
                                        with the family name placed first, and append the term of address. :)
                                        (: Dates are appended last, once for the whole name. :)
                                        (: Example: "Freud, Sigmund, Dr. (1856-1939)". :)
                                        then
                                            concat
                                            (
                                                (: There may be several instances of the same type of name part; these are joined with a space in between. :)
                                                string-join($family-name-basic/mods:namePart[. != ''], ' ') 
                                                ,
                                                if (string($family-name-basic) and string($given-name-basic))
                                                (: If only one of family and given are evidenced, no comma is needed. :)
                                                then
                                                    if ($nameOrder-basic eq 'family-given')
                                                    then ' '
                                                    else ', '
                                                else ()
                                                ,
                                                string-join($given-name-basic/mods:namePart[. != ''], ' ') 
                                                ,
                                                if (string($termsOfAddress-basic))
                                                then 
                                                    if ($termsOfAddress-basic = ('Jr.', 'Sr.') or contains($termsOfAddress-basic, 'I'))
                                                    (:"I" is for generation, I, II, III:)
                                                    (: If there are several terms of address, join them with a comma in between ("Dr., Prof."). :)
                                                    then ()
                                                    else concat(', ', string-join($termsOfAddress-basic/mods:namePart[. != ''], ', ')) 
                                                else ()
                                            )
                                        else
                                            if ($nameOrder-basic eq 'family-given')
                                            (: If the name is Hungarian and does not occur in list-first position. :)
                                            then 
                                                concat
                                                (
                                                    string-join($family-name-basic/mods:namePart[. != ''], ' ') 
                                                    ,
                                                    if (string($family-name-basic) and string($given-name-basic))
                                                    then 
                                                        if ($language-basic eq 'hun')
                                                        then ' '
                                                        else ''
                                                    else ()
                                                    ,
                                                    string-join($given-name-basic/mods:namePart, ' ') 
                                                    ,
                                                    if (string($termsOfAddress-basic))
                                                    (: NB: Where do terms of address go in Hungarian? :)
                                                    then concat(', ', string-join($termsOfAddress-basic/mods:namePart, ', ')) 
                                                    else ()
                                                )
                                            else
                                            (: In all other situations, the name order is given-family, with a space in between. :)
                                            (: Example: "Dr. Sigmund Freud (1856-1939)". :)
                                                concat
                                                (
                                                    if (string($termsOfAddress-basic))
                                                    then concat(string-join($termsOfAddress-basic/mods:namePart, ', '), ' ')
                                                    else ()
                                                    ,
                                                    string-join($given-name-basic/mods:namePart, ' ')
                                                    ,
                                                    if (string($family-name-basic) and string($given-name-basic))
                                                    then ' '
                                                    else ()
                                                    ,
                                                    string-join($family-name-basic/mods:namePart, ' ')
                                                )
                        (: If there is no $name-basic, output nothing. :)
                        else ()
                                                    
                        (: ## 2 ##:)
                        let $transliterated-name :=
                        
                        if (string($name-in-transliteration))
                        (: If we have a name in transliteration, e.g. be a Chinese name or a Russian name, filter the name parts according to type. :)
                        then
                            let $untyped-name-in-transliteration := <name>{$name-in-transliteration/mods:namePart[not(@type)]}</name>
                            let $family-name-in-transliteration := <name>{$name-in-transliteration/mods:namePart[@type eq 'family']}</name>
                            let $given-name-in-transliteration := <name>{$name-in-transliteration/mods:namePart[@type eq 'given']}</name>
                            let $termsOfAddress-in-transliteration := <name>{$name-in-transliteration/mods:namePart[@type eq 'termsOfAddress']}</name>
                            (: To get the name order, get the language of the namePart and send it to mods-common:get-name-order(), along with higher-level language values. :)
                            let $language-in-transliteration := 
                                if ($family-name-in-transliteration/mods:namePart/@lang)
                                then $family-name-in-transliteration/mods:namePart/@lang
                                else
                                    if ($given-name-in-transliteration/mods:namePart/@lang)
                                    then $given-name-in-transliteration/mods:namePart/@lang
                                    else
                                        if ($termsOfAddress-in-transliteration/mods:namePart/@lang)
                                        then $termsOfAddress-in-transliteration/mods:namePart/@lang
                                        else
                                            if ($untyped-name-in-transliteration/mods:namePart/@lang)
                                            then $untyped-name-in-transliteration/mods:namePart/@lang
                                            else ()
                            let $nameOrder-in-transliteration := mods-hra:get-name-order($language-in-transliteration, distinct-values($name-language), $global-language)
                            
                            return       
                                (: If there are name parts that are not typed, there is nothing we can do to order their sequence. :)
                                if (string($untyped-name-in-transliteration))
                                then string-join($untyped-name-in-transliteration/mods:namePart, ' ') 
                                else
                                (: If the name parts are typed, we have a name that is a transliteration and that is divided into given and family name. 
                                If the name order is family-given, we have an ordinary Oriental name in transliteration, 
                                if the name order is given-family, we have e.g. a Russian name in transliteration. :)
                                    if ($position eq 1 and $destination eq 'list-first' and $nameOrder-in-transliteration ne 'family-given')
                                    (: If the name occurs first in list view and the name is not a name that occurs in family-given sequence, e.g. a Russian name, format it with a comma between family name and given name, with family name placed first. :)
                                    then
                                    concat(
                                        string-join($family-name-in-transliteration/mods:namePart, ' ') 
                                        , 
                                        if (string($family-name-in-transliteration) and string($given-name-in-transliteration))
                                        then ', '
                                        else ()
                                        ,
                                        string-join($given-name-in-transliteration/mods:namePart, ' ') 
                                        ,
                                        if (string($termsOfAddress-in-transliteration)) 
                                        then concat(', ', string-join($termsOfAddress-in-transliteration/mods:namePart, ', ')) 
                                        else ()
                                    )
                                    else
                                    (: In all other situations, the name order is given-family; 
                                    the difference is whether there is a space between the name parts and the order of name proper and the address. :)
                                        if ($nameOrder-in-transliteration ne 'family-given')
                                        (: If it is e.g. a Russian name. :)
                                        then
                                            concat(
                                                if (string($termsOfAddress-in-transliteration)) 
                                                then concat(', ', string-join($termsOfAddress-in-transliteration/mods:namePart, ', ')) 
                                                else ()
                                                ,
                                                string-join($given-name-in-transliteration/mods:namePart, ' ')
                                                ,
                                                if (string($family-name-in-transliteration) and string($given-name-in-transliteration))
                                                then ' '
                                                else ()
                                                ,
                                                string-join($family-name-in-transliteration/mods:namePart, ' ')
                                            )
                                        else
                                        (: If it is e.g. a Chinese or a Japanese name. :)
                                            concat(
                                                string-join($family-name-in-transliteration, '')
                                                ,
                                                if (string($family-name-in-transliteration) and string($given-name-in-transliteration))
                                                then ' '
                                                else ()
                                                ,
                                                string-join($given-name-in-transliteration, '')
                                                ,
                                                if (string($termsOfAddress-in-transliteration)) 
                                                then concat(' ', string-join($termsOfAddress-in-transliteration/mods:namePart, ' ')) 
                                                else ()
                                            )
                        else ()

                        (: ## 3 ##:)
                        let $orignal-script-name :=
                            if (string($name-in-non-latin-script))
                            then
                                let $untyped-name-in-non-latin-script := <name>{$name-in-non-latin-script/mods:namePart[not(@type)]}</name>
                                let $family-name-in-non-latin-script := <name>{$name-in-non-latin-script/mods:namePart[@type eq 'family']}</name>
                                let $given-name-in-non-latin-script := <name>{$name-in-non-latin-script/mods:namePart[@type eq 'given']}</name>
                                let $termsOfAddress-in-non-latin-script := <name>{$name-in-non-latin-script/mods:namePart[@type eq 'termsOfAddress']}</name>
                                let $language-in-non-latin-script := 
                                    if ($family-name-in-non-latin-script/mods:namePart/@lang)
                                    then $family-name-in-non-latin-script/mods:namePart/@lang
                                    else
                                        if ($given-name-in-non-latin-script/mods:namePart/@lang)
                                        then $given-name-in-non-latin-script/mods:namePart/@lang
                                        else
                                            if ($termsOfAddress-in-non-latin-script/mods:namePart/@lang)
                                            then $termsOfAddress-in-non-latin-script/mods:namePart/@lang
                                            else
                                                if ($untyped-name-in-non-latin-script/mods:namePart/@lang)
                                                then $untyped-name-in-non-latin-script/mods:namePart/@lang
                                                else ()
                                let $nameOrder-in-non-latin-script := mods-hra:get-name-order($language-in-non-latin-script, distinct-values($name-language), $global-language)
                                return       
                                    if (string($untyped-name-in-non-latin-script))
                                    (: If the name parts are not typed, there is nothing we can do to order their sequence. When name parts are not typed, it is generally because the whole name occurs in one name part, formatted for display (usually with a comma between family and given name), but it may also be used when names that cannot be divided into family and given names are in evidence. We trust that any sequence of nameparts are meaningfully ordered and string-join them. :)
                                    then string-join($untyped-name-in-non-latin-script, ' ') 
                                    else
                                    (: If the name parts are typed, we have a name that is not a transliteration, 
                                    that is not in a non-Latin script 
                                    and that is divided into given and family name. An ordinary Western name. :)
                                        if ($position eq 1 and $destination eq 'list-first' and $nameOrder-in-non-latin-script ne 'family-given')
                                        (: If the name occurs first in list view and the name is not a name that occurs in family-given sequence, 
                                        format it with a comma between family name and given name, with family name first. :)
                                        then
                                        concat(
                                            string-join($family-name-in-non-latin-script/mods:namePart, ' ')
                                            , 
                                            if (string($family-name-in-non-latin-script) and string($given-name-in-non-latin-script))
                                            then ', '
                                            else ()
                                            ,
                                            string-join($given-name-in-non-latin-script/mods:namePart, ' ')
                                            ,
                                            if (string($termsOfAddress-in-non-latin-script)) 
                                            then concat(', ', string-join($termsOfAddress-in-non-latin-script, ', ')) 
                                            else ()
                                        )
                                        else
                                            (: If the name does not occur first in first in list view and if the name does not occur in family-given sequence, 
                                            format it with a space between given name and family name, with given name placed first. 
                                            This would be the case with Russian names that are not first in author position in the list view. :)
                                            if ($nameOrder-in-non-latin-script ne 'family-given')
                                            then
                                                concat(
                                                    if (string($termsOfAddress-in-non-latin-script))
                                                    then concat(string-join($termsOfAddress-in-non-latin-script, ', '), ' ')
                                                    else ()
                                                    ,
                                                    string-join($given-name-in-non-latin-script/mods:namePart, ' ')
                                                    ,
                                                    if (string($family-name-in-non-latin-script) and string($given-name-in-non-latin-script))
                                                    then ' '
                                                    else ()
                                                    ,
                                                    string-join($family-name-in-non-latin-script/mods:namePart, ' ')
                                                )
                                            else
                                            (: $nameOrder-in-non-latin-script eq 'family-given'. 
                                            Here we have e.g. Chinese names which are the same wherever they occur, with no space or comma between given and family name. :)
                                                concat(
                                                    string-join($family-name-in-non-latin-script, '')
                                                    ,
                                                    string-join($given-name-in-non-latin-script, '')
                                                    ,
                                                    string-join($termsOfAddress-in-non-latin-script, '')
                                                    (:
                                                    ,
                                                    if (string($dateScript))
                                                    then concat(' (', string-join($dateScript, ', ') ,')')
                                                    else ()
                                                    :)
                                                )
                            else ()

                        
                        let $name-date :=
                            if ($date-basic)
                            then concat(' (', $date-basic, ')')
                            else ()
                        
                        let $both-eastern-and-western-name :=
                            if ($name/mods:namePart[not(@type eq 'date')][not(@lang = $mods-hra:given-name-last-languages) or not(@lang)])
                            then
                                if ($name/mods:namePart[not(@type eq 'date')][@lang = $mods-hra:given-name-last-languages])
                                then true()
                                else ()
                            else ()
                            
                        return 
                            <span>
                                <span class="name">
                                    {
                                        concat($basic-name
                                        , ' ', 
                                        if ($both-eastern-and-western-name)
                                        then ' ('
                                        else ()
                                        ,
                                        $transliterated-name
                                        , ' ', 
                                        $orignal-script-name
                                        ,
                                        if ($both-eastern-and-western-name)
                                        then ') '
                                        else ()
                                        ,
                                        $name-date
                                        ,
                                        if ($description) 
                                        then concat(' (as ', $description, ')')
                                        else ()
                                        )
                                    }
                                </span>
                                <a class="name-link" onclick="tamboti.apis.advancedSearchWithData({serialize($advanced-search-data, map {"method": "json"})}" href="#" title="Find all records with the same name">
                                    (find all records)
                                </a>
                            </span>

};
    
(:~
: The <b>mods-common:get-name-order</b> function returns 
: 'family-given' for languages in which the family name occurs,
: according to the code-table language-3-type.xml.
: before the given name.
:
: @author Jens Østergaard Petersen
: @param $namePart-language The string value of the @lang attribute on namePart
: @param $name-language The string value of the @lang attribute on name
: @param $global-language The string value of mods/language/languageTerm
: @return $nameOrder The string 'family-given' or the empty string
:)
declare function mods-hra:get-name-order($namePart-language as xs:string*, $name-language as xs:string*, $global-language as xs:string?) {
    let $language :=
        (:This appears to be needed if several namePart have @lang and name does not. We assume that they have the same @lang.:)
        if (distinct-values($namePart-language))
            then distinct-values($namePart-language)
            else
                if (distinct-values($name-language))
                then distinct-values($name-language)
                else
                    if ($global-language)
                    then $global-language
                    else ()
    let $nameOrder := doc(concat($config:db-path-to-mods-editor-home, '/code-tables/language-3-type.xml'))/mods-editor:code-table/mods-editor:items/mods-editor:item[mods-editor:value eq $language]/mods-editor:nameOrder/text()
    return $nameOrder
};    

declare function mods-hra:generate-computed-indexes($resource) {
    map {
        "authors": mods-hra:get-author($resource),
        "title": mods-hra:get-short-title($resource),
        "year": mods-hra:get-year($resource),
        "names": mods-hra:get-names($resource),
        "id": $resource/@ID
    }
};
