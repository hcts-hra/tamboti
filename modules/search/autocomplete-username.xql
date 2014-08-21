xquery version "3.0";

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace sm = "http://exist-db.org/xquery/securitymanager";

import module namespace sharing="http://exist-db.org/mods/sharing" at "sharing.xqm";
import module namespace security="http://exist-db.org/mods/security" at "security.xqm";
import module namespace config="http://exist-db.org/mods/config" at "config.xqm";


declare option exist:serialize "method=text media-type=text/javascript";

let $term := request:get-parameter("term", ()) return

    fn:concat("[",
        fn:string-join(
            for $username in sm:find-users-by-name-part($term)
                let $user-fullname := system:as-user($config:dba-credentials[1], $config:dba-credentials[2], security:get-human-name-for-user($username))
                order by $user-fullname
            return
                (: not current user, can be remote user or user from biblio users group :)
                if(sharing:is-valid-user-for-share($username)) then
                        if (fn:contains($username, "@")) then
                            """" || $user-fullname || " (" || $username || ")" || """"
                        else
                            """" || $username || """"
                else(),
            ', '
        ),
        "]")