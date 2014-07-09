xquery version "3.0";

import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "../../modules/search/security.xqm";

declare namespace earl = "http://www.w3.org/ns/earl#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare variable $parent-collection := xs:anyURI("/apps/" || $config:actual-app-id || "/tests/resources/temp");
declare variable $test-collection := xs:anyURI("/apps/" || $config:actual-app-id || "/tests/resources/temp/VRA_images");
declare variable $test-resource := xs:anyURI("/apps/" || $config:actual-app-id || "/tests/resources/temp/VRA_images/w_fecddb51-9a2c-4510-881f-1443166bd400.xml");
declare variable $expected-result :=
    <sm:acl entries="2">
        <sm:ace index="0" target="USER" who="{$config:biblio-admin-user}" access_type="ALLOWED" mode="rwx"/>
        <sm:ace index="1" target="GROUP" who="{$config:biblio-users-group}" access_type="ALLOWED" mode="rwx"/>
    </sm:acl>
;

declare function local:clear-aces($path as xs:anyURI) {
    (
        sm:remove-ace($path, 0),
        sm:remove-ace($path, 0)
    )
};

(
    sm:add-user-ace($parent-collection, $config:biblio-admin-user, true(), "rwx"),
    sm:add-group-ace($parent-collection, $config:biblio-users-group, true(), "rwx"),
    security:duplicate-acl($parent-collection, $test-collection),
    security:duplicate-acl($parent-collection, $test-resource),
    if (sm:get-permissions($test-collection)/*/* eq $expected-result and sm:get-permissions($test-resource)/*/* eq $expected-result)
    then
        <earl:TestResult rdf:about="#result">
            <earl:outcome rdf:resource="http://www.w3.org/ns/earl#passed"/>
        </earl:TestResult>        
    else
        <earl:TestResult rdf:about="#result">
            <earl:outcome rdf:resource="http://www.w3.org/ns/earl#failed"/>
        </earl:TestResult>,
    local:clear-aces($test-resource),
    local:clear-aces($test-collection),    
    local:clear-aces($parent-collection)
)
