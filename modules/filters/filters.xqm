xquery version "3.0";

module namespace filters = "http://hra.uni-heidelberg.de/ns/tamboti/filters/";

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";

declare variable $filters:eastern-languages := ('chi', 'jpn', 'kor', 'skt', 'tib');

(: An adaption of biblio:order-by-author() from application.xql. Any changes should be coordinated. :)
declare function filters:format-name($name as element()) as xs:string* {
    let $namePart-elements := $name/mods:namePart
    
    let $sortFirst :=
    	(: If there is a namePart marked as being in a Western language, there could in addition be a transliterated and a Eastern-script "nick-name", but the Western namePart should have precedence over the nick-name, therefore pick out the Western-language nameParts first. :)
    	if ($namePart-elements[not(@lang = $filters:eastern-languages)]/text())
    	then
    		(: If it has a family type, take it; otherwise take whatever namePart there is (in case of a name which has not been analysed into given and family names. :)
    		if ($namePart-elements[@type = 'family']/text())
    		then $namePart-elements[not(@lang = $filters:eastern-languages)][@type = 'family'][1]/text()
    		else $namePart-elements[not(@lang = $filters:eastern-languages)][1]/text()
    	else
    		(: If there is not a Western-language namePart, check if there is a namePart with transliteration; if this is the case, take it. :)
	    	if ($namePart-elements[@transliteration]/text())
	    	then
	    		(: If it has a family type, take it; otherwise take whatever transliterated namePart there is. :)
	    		if ($namePart-elements[@type = 'family']/text())
	    		then $namePart-elements[@type = 'family'][@transliteration][1]/text()
		    	else $namePart-elements[@transliteration][1]/text()
		    else
		    	(: If the name does not have a transliterated namePart, it is probably a "standard" (unmarked) Western name, if it does not have a script attribute or uses Latin script. :)
	    		if ($namePart-elements[@script eq 'Latn']/text() or $namePart-elements[not(@script)]/text())
	    		then
	    		(: If it has a family type, take it; otherwise takes whatever untransliterated namePart there is.:) 
		    		if ($namePart-elements[@type = 'family']/text())
		    		then $namePart-elements[not(@script) or @script eq 'Latn'][@type = 'family'][1]/text()
	    			else $namePart-elements[not(@script) or @script eq 'Latn'][1]/text()
	    		(: The last step should take care of Eastern filters without transliteration. These will usually have a script attribute. :)
	    		else 
	    			if ($namePart-elements[@type = 'family']/text())
		    		then $namePart-elements[@type = 'family'][1]/text()
	    			else $namePart-elements[1]/text()
	let $sortLast :=
	    	if ($namePart-elements[not(@lang = $filters:eastern-languages)]/text())
	    	then
	    	(: Insert commas before Western given names. :)
	    		concat(', ', $namePart-elements[not(@lang = $filters:eastern-languages)][@type eq 'given'][1]/text())
	    	else
		    	if ($namePart-elements[@transliteration]/text())
		    	then
		    		(: Do not insert commas before Eastern (transliterated) given names. :)
		    		concat(' ', $namePart-elements[@type eq 'given'][@transliteration][1]/text())
			    else
			    	if ($namePart-elements[@script eq 'Latn']/text() or $namePart-elements[not(@script)]/text())
		    		(: Insert commas before Western given names. :)
		    		then concat(', ', $namePart-elements[@type eq 'given'][not(@script) or @script eq 'Latn'][1]/text())
		    		else concat(', ', $namePart-elements[@type eq 'given'][1]/text())
	let $nameOriginalScript :=
			(: If the name has a transliterated namePart, it is probably an Eastern name; extract the name in original script to be appended the transliterated name. :)
	    	if ($namePart-elements[@transliteration]/text())
	    	then
	    		(: If it has a family type, take it; otherwise take whatever transliterated namePart there is. :)
	    		if ($namePart-elements[not(@transliteration)][@type = 'family']/text())
	    		then concat(' ', $namePart-elements[not(@transliteration)][@script][@type = 'family'][1]/text(), $namePart-elements[not(@transliteration)][@script][@type eq 'given'][1]/text())
		    	else concat(' ', $namePart-elements[not(@transliteration)][@script][1]/text())
		    else ()
    let $nameOriginalScript := if ($nameOriginalScript) then $nameOriginalScript else ()
    
    return normalize-space(translate($sortFirst || $sortLast || $nameOriginalScript, '"', "'"))
};

declare function filters:keywords($results as element()*) {
    let $prefix := request:get-parameter("prefix", "")
    let $callback := util:function(xs:QName("filters:key"), 2)
    
    (: NB: Is there any way to get the number of title words? :)
    return distinct-values(util:index-keys($results//(mods:titleInfo | vra:titleSet), $prefix, $callback, (), "lucene-index"))
};

declare function filters:key($key, $options) {
    ($key, $options[1])
};

declare function filters:get-frequencies($filters) {
    map:new(
        for $filter in $filters
        group by $key := $filter
        return map:entry($filter[1], count($filter))
    )
};

