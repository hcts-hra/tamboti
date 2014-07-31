xquery version "3.0";

import module namespace config="http://exist-db.org/mods/config" at "modules/config.xqm";

declare variable $home external;
declare variable $target external;

(    
    (: set special permissions for xquery scripts :)
    sm:chmod(xs:anyURI($target || "/modules/upload/upload.xq"), "rwsr-xr-x"),
    sm:chmod(xs:anyURI($target || "/reports/data-inconsistencies.xq"), "rwsr-xr-x"),
    sm:chmod(xs:anyURI($target || "/modules/administration/fix-for-duplicated-aces.xq"), "rwsr-x---"),
    sm:chmod(xs:anyURI($target || "/reports/reports.xqm"), "rwsr-xr-x"),
    (: make admin:biblio.users as owner of $config:users-collection :)
    sm:chown($config:users-collection, 'admin'),
    sm:chgrp($config:users-collection, $config:biblio-users-group)
)
