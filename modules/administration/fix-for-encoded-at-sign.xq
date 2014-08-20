xquery version "3.0";

import module namespace reports = "http://hra.uni-heidelberg.de/ns/tamboti/reports" at "../../reports/reports.xqm";
import module namespace functx = "http://www.functx.com";

<result>
    {
        for $item in $reports:items-with-encoded-at-sign
        let $item-path := xs:anyURI($item/@path)
        return
            (
                if (matches($item-path, "(%40)[^/]$"))
                then xmldb:rename($item-path, replace(functx:substring-after-last($item-path, '/'), "%40", "@"))
                else ()
            )
    }
</result>
