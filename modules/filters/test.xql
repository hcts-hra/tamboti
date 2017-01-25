xquery version "3.1";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "json";
declare option output:media-type "application/json";

array {
    for $filter in (1 to 1700)
    
    return map {"frequency": $filter, "filter": $filter, "label": $filter}
}
