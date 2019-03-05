xquery version "3.1";

import module namespace sharing="http://exist-db.org/mods/sharing" at "sharing.xqm";
import module namespace security="http://exist-db.org/mods/security" at "security.xqm";


declare option exist:serialize "method=text media-type=text/javascript";

let $term := request:get-parameter("term", "")

return
    concat("[",
        string-join(
            for $username in sm:find-users-by-name-part($term)
            let $user-fullname := security:get-human-name-for-user($username)
            order by $user-fullname
            
            return
                (: not current user, can be remote user or user from biblio users group :)
                if (sharing:is-valid-user-for-share($username))
                then
                    if (contains($username, "@"))
                    then """" || $user-fullname || " (" || $username || ")" || """"
                    else """" || $username || """"
                else()
            ,
            ', '
        ),
    "]")
