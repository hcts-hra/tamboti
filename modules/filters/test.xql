xquery version "3.0";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";

let $processsed-filters :=
    <filters xmlns="">
        {
            for $filter in (1 to 17)
            return <filter frequency="{$filter}" filter="{$filter}">{normalize-space(translate($filter, '"', "'"))}</filter>
        }
    </filters>            

return $processsed-filters
