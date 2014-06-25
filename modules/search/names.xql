module namespace nameutil="http://exist-db.org/xquery/biblio/names";

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";

declare variable $nameutil:eastern-languages := ('chi', 'jpn', 'kor', 'skt', 'tib');

(: Called from filter.xql. :)
(: An adaption of biblio:order-by-author() from application.xql. Any changes should be coordinated. :)
declare function nameutil:format-name($name as element()) as xs:string* {
    let $vraName := $name//vra:name[1]/text()
    (:let $log := util:log("DEBUG", ("##$vraName): ", $vraName)):)
    let $sortFirst :=
    	(: If there is a namePart marked as being in a Western language, there could in addition be a transliterated and a Eastern-script "nick-name", but the Western namePart should have precedence over the nick-name, therefore pick out the Western-language nameParts first. :)
    	if ($name/mods:namePart[@lang != $nameutil:eastern-languages]/text())
    	then
    		(: If it has a family type, take it; otherwise take whatever namePart there is (in case of a name which has not been analysed into given and family names. :)
    		if ($name/mods:namePart[@type eq 'family']/text())
    		then $name/mods:namePart[@lang != $nameutil:eastern-languages][@type eq 'family'][1]/text()
    		else $name/mods:namePart[@lang != $nameutil:eastern-languages][1]/text()
    	else
    		(: If there is not a Western-language namePart, check if there is a namePart with transliteration; if this is the case, take it. :)
	    	if ($name/mods:namePart[@transliteration]/text())
	    	then
	    		(: If it has a family type, take it; otherwise take whatever transliterated namePart there is. :)
	    		if ($name/mods:namePart[@type eq 'family']/text())
	    		then $name/mods:namePart[@type eq 'family'][@transliteration][1]/text()
		    	else $name/mods:namePart[@transliteration][1]/text()
		    else
		    	(: If the name does not have a transliterated namePart, it is probably a "standard" (unmarked) Western name, if it does not have a script attribute or uses Latin script. :)
	    		if ($name/mods:namePart[@script eq 'Latn']/text() or $name/mods:namePart[not(@script)]/text())
	    		then
	    		(: If it has a family type, take it; otherwise takes whatever untransliterated namePart there is.:) 
		    		if ($name/mods:namePart[@type eq 'family']/text())
		    		then $name/mods:namePart[not(@script) or @script eq 'Latn'][@type eq 'family'][1]/text()
	    			else $name/mods:namePart[not(@script) or @script eq 'Latn'][1]/text()
	    		(: The last step should take care of Eastern names without transliteration. These will usually have a script attribute. :)
	    		else 
	    			if ($name/mods:namePart[@type eq 'family']/text())
		    		then $name/mods:namePart[@type eq 'family'][1]/text()
	    			else $name/mods:namePart[1]/text()
	let $sortLast :=
	    	if ($name/mods:namePart[@lang != $nameutil:eastern-languages]/text())
	    	then
	    	(: Insert commas before Western given names. :)
	    		concat(', ', $name/mods:namePart[@lang != $nameutil:eastern-languages][@type eq 'given'][1]/text())
	    	else
		    	if ($name/mods:namePart[@transliteration]/text())
		    	then
		    		(: Do not insert commas before Eastern (transliterated) given names. :)
		    		concat(' ', $name/mods:namePart[@type eq 'given'][@transliteration][1]/text())
			    else
			    	if ($name/mods:namePart[@script eq 'Latn']/text() or $name/mods:namePart[not(@script)]/text())
		    		(: Insert commas before Western given names. :)
		    		then concat(', ', $name/mods:namePart[@type eq 'given'][not(@script) or @script eq 'Latn'][1]/text())
		    		else concat(', ', $name/mods:namePart[@type eq 'given'][1]/text())
	let $nameOriginalScript :=
			(: If the name has a transliterated namePart, it is probably an Eastern name; extract the name in original script to be appended the transliterated name. :)
	    	if ($name/mods:namePart[@transliteration]/text())
	    	then
	    		(: If it has a family type, take it; otherwise take whatever transliterated namePart there is. :)
	    		if ($name/mods:namePart[not(@transliteration)][@type eq 'family']/text())
	    		then concat(' ', $name/mods:namePart[not(@transliteration)][@script][@type eq 'family'][1]/text(), $name/mods:namePart[not(@transliteration)][@script][@type eq 'given'][1]/text())
		    	else concat(' ', $name/mods:namePart[not(@transliteration)][@script][1]/text())
		    else ()
    return
        if ($vraName) 
        then $vraName 
        else
            concat(
            	$sortFirst,
            	$sortLast, 
    	        	if ($nameOriginalScript) 
    	        	then $nameOriginalScript
    	        	else ()
    	        )
};