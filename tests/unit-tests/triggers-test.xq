xquery version "3.0";

let $log := util:log("INFO", "Cleanup trigger tests")
let $clear-test-collections := 
    (
        if(xmldb:collection-available("/db/data/users/editor/triggertest")) then
            xmldb:remove("/db/data/users/editor/triggertest")
        else 
            ()
        ,
        if(xmldb:collection-available("/db/data/users/editor/triggertest2")) then
            xmldb:remove("/db/data/users/editor/triggertest2")
        else 
            ()
        ,
        if(xmldb:collection-available("/db/data/users/editor/triggertest3")) then
            xmldb:remove("/db/data/users/editor/triggertest3")
        else 
            ()
    )
let $log := util:log("INFO", "Starting trigger tests")
return
    (
        (:   COLLECTION TRIGGERS   :)
(: create collection "test" in "/db/data/users/editor/triggertest" :)
        xmldb:create-collection("/db/data/users/editor", "triggertest"),
        xmldb:create-collection("/db/data/users/editor/triggertest", "test"),
        sm:get-permissions(xs:anyURI("/db/data/users/editor/triggertest/test"))
        ,
        (: create collection "test2" in "/db/data/users/editor/triggertest" :)
        xmldb:create-collection("/db/data/users/editor/triggertest", "test2")
        ,
        (: create collection "test2" in "/db/data/users/editor/triggertest" :)
        xmldb:create-collection("/db/data/users/editor/triggertest", "test3")
        ,
        (: copy collection "/db/data/users/editor/triggertest" into "/db/data/users/editor/triggertest2" :)
        util:log("INFO", "copy from /db/data/users/editor/triggertest to /db/data/users/editor/triggertest2/test"),
        xmldb:copy("/db/data/users/editor/triggertest", "/db/data/users/editor/triggertest/test2"),
        sm:get-permissions(xs:anyURI("/db/data/users/editor/triggertest/test2"))
        ,
        (: move collection "/db/data/users/editor/triggertest2" to "/db/data/users/editor/triggertest3" :)
        util:log("INFO", "move from /db/data/users/editor/triggertest2 to /db/data/users/editor/triggertest3/test2"),
        xmldb:move("/db/data/users/editor/triggertest2", "/db/data/users/editor/triggertest3"),
        sm:get-permissions(xs:anyURI("/db/data/users/editor/triggertest/test/triggertest3"))
        ,
        (: remove /db/data/users/editor/triggertest3/test2/test:)
        xmldb:remove("/db/data/users/editor/triggertest3/test2/test")
        ,
        (:   RESSOURCE TRIGGERS   :)
        (: create ressource "res.xml" in "/db/data/users/editor/triggertest3" :)
        xmldb:store("/db/data/users/editor/triggertest3", "res.xml", <test>test</test>),
        sm:get-permissions(xs:anyURI("/db/data/users/editor/triggertest/test/triggertest2/res.xml"))
        ,
        (: modify res.xml:)
        update insert <test2>test2</test2>
        into doc("/db/data/users/editor/triggertest3/res.xml")/test
        ,
        (: copy ressource "res.xml" to "/db/data/users/editor/triggertest" :)
        util:log("INFO", "copy from /db/data/users/editor/triggertest3/res.xml to /db/data/users/editor/triggertest/res.xml"),
        xmldb:copy("/db/data/users/editor/triggertest3", "/db/data/users/editor/triggertest", "res.xml"),
        sm:get-permissions(xs:anyURI("/db/data/users/editor/triggertest/test/triggertest2/res.xml"))
        ,
        (: move ressource "res.xml" back to "/db/data/users/editor/triggertest3" :)
        util:log("INFO", "move from /db/data/users/editor/triggertest/res.xml to /db/data/users/editor/triggertest3/res.xml"),
        xmldb:move("/db/data/users/editor/triggertest", "/db/data/users/editor/triggertest3", "res.xml"),
        sm:get-permissions(xs:anyURI("/db/data/users/editor/triggertest/test/triggertest3/res.xml"))
        ,
        (: delete "res.xml" :)
        xmldb:remove("/db/data/users/editor/triggertest3", "res.xml")
)