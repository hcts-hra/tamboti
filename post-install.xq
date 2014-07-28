xquery version "3.0";

declare variable $home external;
declare variable $target external;


(    
    (: set special permissions for xquery scripts :)
    sm:chmod(xs:anyURI($target || "/modules/upload/upload.xq"), "rwsr-x---"),
    sm:chmod(xs:anyURI($target || "/reports/data-inconsistencies.xq"), "rwsr-xr-x"),
    sm:chmod(xs:anyURI($target || "/modules/administration/fix-for-duplicated-aces.xq"), "rwsr-x---"),
    sm:chmod(xs:anyURI($target || "/reports/reports.xqm"), "rwsr-xr-x")
)
