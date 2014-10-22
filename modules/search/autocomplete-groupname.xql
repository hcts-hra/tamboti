xquery version "3.0";

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace sm = "http://exist-db.org/xquery/securitymanager";

import module namespace sharing="http://exist-db.org/mods/sharing" at "sharing.xqm";

declare option exist:serialize "method=text media-type=text/javascript";

let $term := request:get-parameter("term", ()) return

    fn:concat("[",
        fn:string-join(
            for $groupname in sm:find-groups-where-groupname-contains($term) return
                (: not current user, can be remote user or user from biblio users group :)
                if(sharing:is-valid-group-for-share($groupname))then
                    fn:concat("""", $groupname, """")
                else(),
            ', '
        ),
        "]")