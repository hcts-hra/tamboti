xquery version "3.0";

import module namespace security="http://exist-db.org/mods/security" at "../../modules/search/security.xqm";
import module namespace sharing="http://exist-db.org/mods/sharing" at "../../modules/search/sharing.xqm";
import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";

declare function local:get-shared-collection-roots($write-required as xs:boolean) as xs:string* {
    let $user-id := security:get-user-credential-from-session()[1]
    
    return
    if (fn:not(($user-id eq 'guest'))) then
        system:as-user($config:dba-credentials[1], $config:dba-credentials[2],
            for $child-collection in xmldb:get-child-collections($config:users-collection)
            let $child-collection-path := fn:concat($config:users-collection, "/", $child-collection) return
                for $user-subcollection in xmldb:get-child-collections($child-collection-path)
                let $user-subcollection-path := fn:concat($child-collection-path, "/", $user-subcollection) return
                    let $ace-mode := data(sm:get-permissions(xs:anyURI($user-subcollection-path))//sm:ace[@who = $user-id]/@mode)
                    return
                        if($write-required)
                            then
                                if (contains($ace-mode, 'w'))
                                    then $user-subcollection-path
                                    else ()                            
                            else
                                if (contains($ace-mode, 'r'))
                                    then $user-subcollection-path
                                    else ()
        )
    else()
};

let $collection-path := xs:anyURI($config:users-collection || "/gd079@ad.uni-heidelberg.de/MyFirstWorkingFolder")

let $user := security:get-user-credential-from-session()[1]

return
    (
        sm:get-permissions($collection-path),
        xmldb:get-child-resources($collection-path),
        local:get-shared-collection-roots(false())
    )