xquery version "3.1";

import module namespace dbutil="http://exist-db.org/xquery/dbutil";

declare namespace sm = "http://exist-db.org/xquery/securitymanager";

dbutil:scan(xs:anyURI(xmldb:encode("resources/users/matthias.guth@ad.uni-heidelberg.de/GrabungKMHKastellweg")),
    function($subcollection-path, $resource-path) {
        if ($resource-path)
        then
            let $path := xs:anyURI($resource-path)
            let $aces := sm:get-permissions($path)//sm:ace
            
            return (
                if ($aces//@who = 'armin.volkmann@ad.uni-heidelberg.de')
                then ()
                else sm:add-user-ace($path, "armin.volkmann@ad.uni-heidelberg.de", true(), "rwx")
                ,
                if ($aces//@who = 'marnold1@ad.uni-heidelberg.de')
                then ()
                else sm:add-user-ace($path, "marnold1@ad.uni-heidelberg.de", true(), "rwx")
            )
        else
            let $path := xs:anyURI($subcollection-path)
            let $aces := sm:get-permissions($path) 
            
            return (
                if ($aces//@who = 'armin.volkmann@ad.uni-heidelberg.de')
                then ()
                else sm:add-user-ace($path, "armin.volkmann@ad.uni-heidelberg.de", true(), "rwx")
                ,
                if ($aces//@who = 'marnold1@ad.uni-heidelberg.de')
                then ()
                else sm:add-user-ace($path, "marnold1@ad.uni-heidelberg.de", true(), "rwx")
            )
    }
)
