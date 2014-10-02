xquery version "3.0";

import module namespace config="http://exist-db.org/mods/config" at "modules/config.xqm";

declare variable $home external;
declare variable $target external;

declare function local:set-special-permissions($path as xs:anyURI) {
    (
        sm:chown($path, "admin")
        ,
        sm:chgrp($path, "dba")
        ,
        sm:chmod($path, "rwsr-xr-x")
    )
};

(    
    (: set special permissions for xquery scripts :)
    sm:chmod(xs:anyURI($target || "/modules/upload/upload.xq"), "rwsr-xr-x"),
    local:set-special-permissions(xs:anyURI($target || "/reports/data-inconsistencies.xq")),
    sm:chmod(xs:anyURI($target || "/modules/administration/fix-for-duplicated-aces.xq"), "rwsr-x---"),
    local:set-special-permissions(xs:anyURI($target || "/reports/reports.xqm")),
    (: make admin:biblio.users as owner of $config:users-collection :)
    sm:chown($config:users-collection, 'admin'),
    sm:chgrp($config:users-collection, $config:biblio-users-group)
)
