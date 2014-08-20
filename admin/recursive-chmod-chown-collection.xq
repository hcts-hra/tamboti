xquery version "3.0";

declare variable $group-id := "biblio.users";
declare variable $user-id := "vma-editor";

declare function local:set-user-group-permissions($path, $user-id) {
    (
        xmldb:set-collection-permissions($path, $user-id, $group-id, util:base-to-integer(0755, 8))
        ,
        for $col in xmldb:get-child-collections($path)
            return
                (
                xmldb:set-collection-permissions($path || "/" || $col, $user-id, $group-id, util:base-to-integer(0755, 8)),
                local:set-user-group-permissions($path || "/" ||$col, $user-id)
                )
        ,
        for $res in xmldb:get-child-resources($path)
            return 
                xmldb:set-resource-permissions($path, $res, $user-id, $group-id, util:base-to-integer(0755, 8))
    )
};

declare function local:chmod($path) {
    (
        for $col in xmldb:get-child-collections($path)
            return
                (
                xmldb:chmod-collection($path || "/" || $col , util:base-to-integer(0755, 8)),
                local:chmod($path || "/" ||$col)
                )
        ,
        for $res in xmldb:get-child-resources($path)
            return 
                xmldb:chmod-resource($path, $res, util:base-to-integer(0755, 8))
    )
};


let $path := "/resources/users/vma-editor/VMA-Collection/Sunil%20Gupta"

return 
    local:set-user-group-permissions($path, $user-id)
