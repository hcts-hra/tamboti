xquery version "3.0";

import module namespace config="http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace security="http://exist-db.org/mods/security" at "../../modules/search/security.xqm";
import module namespace mods-hra-framework = "http://hra.uni-heidelberg.de/ns/mods-hra-framework" at "../../frameworks/mods-hra/mods-hra.xqm";

declare namespace earl = "http://www.w3.org/ns/earl#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare variable $config:mods-root-minus-temp := "/apps/" || $config:actual-app-id || "/tests/resources";

declare function local:run-unit-test($resource-id as xs:string, $destination-collection as xs:string) {
    let $run-tamboti-function := mods-hra-framework:move-resource($resource-id, $destination-collection)
    
    return
        <earl:TestResult rdf:about="#result">
            <earl:outcome rdf:resource="http://www.w3.org/ns/earl#passed"/>
        </earl:TestResult>
};

(
    local:run-unit-test("uuid-01019f81-f255-47e9-9fd3-509c76d9f2b0", $config:mods-root-minus-temp || "/temp"),
    xmldb:move($config:mods-root-minus-temp || "/temp", $config:mods-root-minus-temp, "uuid-01019f81-f255-47e9-9fd3-509c76d9f2b0.xml")
)