xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace sharing = "http://exist-db.org/mods/sharing" at "../../modules/search/sharing.xqm";

let $collection-path := xs:anyURI("/resources/commons")
let $username := "a9k"

return
    (
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
    )
