xquery version "3.0";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

let $processsed-filters :=
    <filters xmlns="">
        {
            for $filter in (1 to 1700)
            
            return <filter frequency="{$filter}" filter="{$filter}" label="{$filter}" />
        }
    </filters>            

return $processsed-filters
