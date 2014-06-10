xquery version "1.0";

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace sm = "http://exist-db.org/xquery/securitymanager";

import module namespace sharing="http://exist-db.org/mods/sharing" at "sharing.xqm";

declare option exist:serialize "method=text media-type=text/javascript";

let $term := request:get-parameter("term", ()) return

    fn:concat("[",
        fn:string-join(
            for $username in sm:find-users-by-name-part($term) return
                (: not current user, can be remote user or user from biblio users group :)
                if(sharing:is-valid-user-for-share($username))then
                    fn:concat("""", $username, """")
                else(),
            ', '
        ),
        "]")