xquery version "3.0";

declare variable $group-id := "biblio.users";

declare function local:set-user-group-permissions($path, $user-id) {
    (
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


let $path := "/resources/users"
return 
    (
        local:chmod($path)
        
(:        local:set-user-group-permissions($path),:)
 
(:        for $user-id in xmldb:get-users("biblio.users"):)
(:        let $collection-name := $path || "/" || $user-id:)
(:        let $collection-exists := xmldb:collection-available($collection-name):)
(:        return :)
(:            if ($collection-exists):)
(:                then (local:set-user-group-permissions($collection-name, $user-id)):)
(:                else($collection-name || ": " || $collection-exists):)

(:        for $col in xmldb:get-child-collections($path):)
(:        let $collection-name := $path || "/" || $col:)
(:        let $user-id := replace($col, "%40", "@"):)
(:        let $user-exists := xmldb:exists-user($user-id):)
(:        return:)
(:            if ($user-exists):)
(:                then (:)
(:                        xmldb:set-collection-permissions($collection-name, $user-id, $group-id, util:base-to-integer(0755, 8)),:)
(:                        local:set-user-group-permissions($collection-name, $user-id):)
(:                    ):)
(:                else($col):)
    )