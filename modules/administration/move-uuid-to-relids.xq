xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "/db/apps/tamboti/modules/config.xqm";

declare namespace vra="http://www.vraweb.org/vracore4.htm";

declare function local:move-uuid($collection-uri as xs:anyURI) {
    for $res in collection($collection-uri)//vra:work
    return
        for $relation in $res//vra:relationSet//vra:relation[@type="imageIs"]
        return
            if(starts-with($relation/@refid, "i_")) then
                (
                    update insert attribute relids {$relation/@refid} into $relation,
                    update delete $relation/@refid,
                    $relation
                )
            else
                ()
            
};

let $uri := xs:anyURI($config:mods-root || "/commons/Priya_Paul_Collection")
return 
    local:move-uuid($uri)
