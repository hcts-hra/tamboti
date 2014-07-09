xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace tamboti-utils = "http://hra.uni-heidelberg.de/ns/tamboti/utils" at "../../modules/utils/utils.xqm";

let $username := tamboti-utils:get-username-from-path("/db/resources/users/editor/test/w_51435356-ff68-45d6-b29a-e3bf88b25d19.xml")

return
    if ($username = $config:biblio-admin-user)
    then
        <earl:TestResult rdf:about="#result">
            <earl:outcome rdf:resource="http://www.w3.org/ns/earl#passed"/>
        </earl:TestResult>
    else 
        <earl:TestResult rdf:about="#result">
            <earl:outcome rdf:resource="http://www.w3.org/ns/earl#failed"/>
        </earl:TestResult>
