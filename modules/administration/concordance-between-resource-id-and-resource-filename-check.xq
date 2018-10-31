xquery version "3.1";

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";
declare namespace svg="http://www.w3.org/2000/svg";
declare namespace tei="http://www.tei-c.org/ns/1.0";

let $resources := collection("/data")/*
            
return
    for $resource in $resources
    let $namespace-uri := namespace-uri($resource)
    let $resource-filename := util:document-name($resource)
    let $resource-id :=
        switch($namespace-uri)
        case "http://www.loc.gov/mods/v3" return $resource/@ID
        case "http://www.tei-c.org/ns/1.0" return $resource/@xml:id
        case "http://www.vraweb.org/vracore4.htm" return $resource/vra:work/@id
        default return ""
        
        
    return 
        if ($resource-id != '')
        then
            if ($resource-filename != $resource-id || ".xml")
            then document-uri($resource/root()) || ", $resource-id = " || $resource-id
            else ()
        else ()    
