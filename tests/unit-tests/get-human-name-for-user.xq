xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace sharing = "http://exist-db.org/mods/sharing" at "../../modules/search/sharing.xqm";

let $collection-path := xs:anyURI("/resources/commons")
let $username := "a9k"

return
    (
(:        sm:remove-ace($collection-path, 2),:)
(:        sm:add-group-ace($collection-path, $config:biblio-users-group, true(), "r--"),:)
(:        system:as-user($config:dba-credentials[1],$config:dba-credentials[2],:)
(:            sm:get-account-metadata(sm:get-permissions($collection-path)//sm:ace[3]/@who, xs:anyURI("http://axschema.org/namePerson/first")):)
(:        ):)
(:        sm:add-user-ace($collection-path, "a29", true(), "rwx"),:)
(:        for $subcollection in xmldb:get-child-collections($collection-path):)
(:        return :)
(:            ( :)
(:                xs:anyURI($collection-path || "/"  || $subcollection),:)
(:                sm:get-permissions(xs:anyURI($collection-path || "/"  || $subcollection))//sm:ace[@who = $config:biblio-admin-user]:)
(:            ) :)
            <result>
                {
                    for $child-collection in xmldb:get-child-collections($config:users-collection)
                    let $child-collection-path := fn:concat($config:users-collection, "/", $child-collection)
                    
                    return
                        for $user-subcollection in xmldb:get-child-collections($child-collection-path)
                        let $user-subcollection-path := fn:concat($child-collection-path, "/", $user-subcollection)
    (:                    let $ace-mode := data(sm:get-permissions(xs:anyURI($user-subcollection-path))//sm:ace[@who = $user-id]/@mode):)
                        
                        return
                            (
                                <collection>{$user-subcollection-path}</collection>,
                                try {
                                        sm:get-permissions(xs:anyURI($user-subcollection-path))
                                } catch * {
                                    "Error at: " || $user-subcollection-path
                                }
                            )
                }
            </result>
(:        xmldb:get-user-groups("claudius.teodorescu"),:)
(:        sm:user-exists($username),:)
(:        sm:get-user-groups($username),:)
(:        sm:remove-account($username):)
(:        sm:add-user-ace($collection-path, "a71", true(), "rwx"),:)
(:        sm:user-exists("a71"):)
    )