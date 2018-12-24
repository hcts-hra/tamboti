xquery version "3.1";

module namespace mods-hra = "http://hra.uni-heidelberg.de/ns/tamboti/mods-hra/";

declare namespace mods="http://www.loc.gov/mods/v3";

declare variable $mods-hra:author-roles := ('aut', 'author', 'cre', 'creator', 'composer', 'cmp', 'artist', 'art', 'director', 'drt', 'photographer', 'pht');
declare variable $mods-hra:eastern-languages := ('chi', 'jpn', 'kor', 'skt', 'tib');

declare function mods-hra:get-author($resource) {
    let $mods-name := /root()/*/mods:name[mods:role/mods:roleTerm = $mods-hra:author-roles or not(mods:role/mods:roleTerm)][1] 
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
    let $resource := $resource/root()/*
    
    return
        (:NB: year is sorted as string.:)
        if ($resource/mods:originInfo[1]/mods:dateIssued[1]) 
        then substring-before($resource/mods:originInfo[1]/mods:dateIssued[1],'-') 
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

declare function mods-hra:generate-computed-indexes($resource) {
    map {
        "author": mods-hra:get-author($resource),
        "year": mods-hra:get-year($resource)
    }
};
