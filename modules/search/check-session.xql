xquery version "3.1";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";


    let $created := session:get-last-accessed-time()
    let $elapsed := util:system-dateTime() - $created
    return
        if ($elapsed gt xs:dayTimeDuration("PT8H")) then
            let $null := session:invalidate()
            return false()
        else
            let $remaining := util:system-dateTime() + xs:dayTimeDuration("PT8H")
            return format-dateTime($remaining, "[h]:[m01]")
            