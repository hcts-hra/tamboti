xquery version "3.0";

declare function local:add-user-ace-to-collection($collection  as xs:anyURI, $username as xs:string, $allowed as xs:boolean, $mode as xs:string) {
    (
        for $resource-name in xmldb:get-child-resources($collection)
        return sm:add-user-ace(xs:anyURI($collection || "/" || $resource-name), $username, $allowed, $mode),
        
        for $collection-name in xmldb:get-child-collections($collection)
        return
            (
                sm:add-user-ace(xs:anyURI($collection || "/" || $collection-name), $username, $allowed, $mode),
                local:add-user-ace-to-collection(xs:anyURI($collection || "/" || $collection-name), $username, $allowed, $mode)
            )
    )  
};

let $collection-path := xs:anyURI("/resources/users/vma-editor/VMA-Collection")

return
    (
        for $ace in sm:get-permissions($collection-path)//sm:ace
        let $username := $ace/@who
        let $allowed := if ($ace/@access_type = "ALLOWED") then (true()) else (false())
        let $mode := $ace/@mode
        return local:add-user-ace-to-collection($collection-path, $username, $allowed, $mode)
    )