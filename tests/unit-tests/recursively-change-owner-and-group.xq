xquery version "3.0";

declare function local:setPerm($path) {
    (
    let $user-id := "vma-editor" 
    let $group-id := "biblio.users" 
    return
        (

        for $col in xmldb:get-child-collections($path)
            return
                (
    (:            $path || "/" || $col,:)
                xmldb:set-collection-permissions($path || "/" || $col , $user-id, $group-id, util:base-to-integer(0755, 8)),
                local:setPerm($path || "/" ||$col)
                )
        ,
        for $res in xmldb:get-child-resources($path)
            return 
                xmldb:set-resource-permissions($path, $res, $user-id, $group-id, util:base-to-integer(0755, 8))
    (:        return "res: " || $res:)
        )
    )
};

let $path := "/resources/users/vma-editor" 
return 
    local:setPerm($path)