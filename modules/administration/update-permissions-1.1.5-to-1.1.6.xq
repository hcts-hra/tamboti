xquery version "3.0";
import module namespace security = "http://exist-db.org/mods/security" at "/db/apps/tamboti/modules/search/security.xqm";
import module namespace config = "http://exist-db.org/mods/config" at "/db/apps/tamboti/modules/config.xqm";

declare function local:get-resource-mode-by-collection-mode($col-mode) {
    let $resource-mode :=
        for $key in map:keys($config:sharing-permissions)
        return
            if ($config:sharing-permissions($key)("collection") = $col-mode) then
                $config:sharing-permissions($key)("resource")
            else
                ()
    return $resource-mode
};

declare function local:adapt-resource-aces($collection-uri as xs:anyURI, $progress-subcollections as xs:boolean) {
    (: update collection mode :)
    let $chmod := sm:chmod($collection-uri, $config:collection-mode)
    (: get ACES for collection :)
    let $collection-aces := sm:get-permissions($collection-uri)//sm:acl/sm:ace
    (: iterate over each collection ace:)
    let $collection-ace-fix :=
        for $ace in $collection-aces
            let $target := $ace/@target/string()
            let $name := $ace/@who/string()
            let $collection-mode := $ace/@mode/string()
            let $new-res-mode := local:get-resource-mode-by-collection-mode($collection-mode)
        
            (: If the collection mode has no resource-mode-correspondency, it is invalid. So set:)
            return 
                if (not($new-res-mode)) then
                    let $ace-idx := $ace/@index/number()
                    (: if write-bit is set, assume the collection should be shared with full access :)
                    let $new-col-mode := 
                        if(matches($collection-mode, ".w.")) then
                            $config:sharing-permissions("full")("collection")
                        else
                            $config:sharing-permissions("readonly")("collection")
                    return
                        try {
                            sm:modify-ace($collection-uri, $ace-idx, true(), $new-col-mode),
                            util:log("INFO", "collection-ace " || $ace-idx || " for " || $collection-uri || " had a wrong mode: " || $collection-mode ||". Set to " || $new-col-mode || "."),
                            true()
                        } catch * {
                            util:log("INFO", "modifying ACE " || $ace || " for " || $collection-uri || " failed.")
                        }
                else
                    false()
    (: reload acl :)
    let $collection-aces := sm:get-permissions($collection-uri)//sm:acl/sm:ace
    (: copy ACL to VRA_Images :)
    let $vra-images-uri := xs:anyURI($collection-uri || "/VRA_images")

    let $vra-images-update :=
        if (xmldb:collection-available($vra-images-uri)) then
            (
                sm:chmod($vra-images-uri, $config:collection-mode),
                (: first delete ACL :)
                sm:clear-acl($vra-images-uri),
                (: then add ACEs :)
                for $ace in $collection-aces
                    let $target := $ace/@target/string()
                    let $name := $ace/@who/string()
                    let $mode := $ace/@mode/string()
                    return
                        if($target="USER") then
                            sm:add-user-ace($vra-images-uri, $name, true(), $mode)
                        else
                            sm:add-group-ace($vra-images-uri, $name, true(), $mode)
            )
        else
            ()
        
    (: iterate over each resource  :)
    for $resource in xmldb:get-child-resources($collection-uri)
        let $fullpath := xs:anyURI($collection-uri || "/" || $resource)
        let $chmod := sm:chmod($fullpath, $config:resource-mode)
        (: remove resource ACL :)
        let $clear := sm:clear-acl($fullpath)
        return
            (: iterate over each collection ace:)
            for $ace in $collection-aces
                let $target := $ace/@target/string()
                let $name := $ace/@who/string()
                let $collection-mode := $ace/@mode/string()
                let $new-res-mode := local:get-resource-mode-by-collection-mode($collection-mode)

                return
                    if($target="USER") then
                        sm:add-user-ace($fullpath, $name, true(), $new-res-mode)
                    else
                        sm:add-group-ace($fullpath, $name, true(), $new-res-mode)
    ,
    (: recursive call ?:)
    if ($progress-subcollections) then
        for $col in xmldb:get-child-collections($collection-uri)
            let $subcol := xs:anyURI($collection-uri || "/" || $col)
            return
                local:adapt-resource-aces($subcol, $progress-subcollections)
    else
        ()
    
};

let $collection-uri := xmldb:encode-uri("/db/data/commons")

return 
    local:adapt-resource-aces($collection-uri, true())
