xquery version "3.0";

let $current-user := xmldb:get-current-user()
let $users-collection-path := "/resources/services/repositories/local/users/"
let $user-collection-path := xs:anyURI($users-collection-path || $current-user || "/")
let $user-subcollection-names := ("persons", "organisations", "subjects")

return
    if (not(xmldb:collection-available($user-collection-path)))
    then
        (
            xmldb:create-collection($users-collection-path, $current-user)
            ,
            for $user-subcollection-name in $user-subcollection-names
            let $user-subcollection-path := xs:anyURI($user-collection-path || $user-subcollection-name)
            return 
            (
                xmldb:create-collection($user-collection-path, $user-subcollection-name)
                ,
                sm:chmod($user-subcollection-path, "rwxr-xr-x")
                ,
                sm:chgrp($user-subcollection-path, "biblio.users")
            )        
        )
    else ()
