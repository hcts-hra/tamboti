xquery version "3.0";

import module namespace dateTime="http://exist-db.org/xquery/datetime"
at "java:org.exist.xquery.modules.datetime.DateTimeModule";

declare namespace json="http://www.json.org";

declare option exist:serialize "method=json media-type=text/javascript";


    let $created := session:get-last-accessed-time()
    let $elapsed := util:system-dateTime() - $created
    return
        if ($elapsed gt xs:dayTimeDuration("PT8H")) then
            let $null := session:invalidate()
            return
                <json:value json:literal="true">{false()}</json:value>
        else
            let $remaining := util:system-dateTime() + xs:dayTimeDuration("PT8H")
            return
                <json:value>{dateTime:format-dateTime($remaining, "hh:mm")}</json:value>