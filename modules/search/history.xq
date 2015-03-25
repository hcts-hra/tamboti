xquery version "3.0";

import module namespace biblio="http://exist-db.org/xquery/biblio" at "application.xql";
import module namespace json="http://www.json.org";

(:~
    Returns the query history as a HTML list. The queries are
    transformed into a simple string representation.
:)
<ul>
{
    let $history := session:get-attribute('history')
    for $query-as-string in $history/query
    let $advanced-search-data :=
        <data>
            <history>{data($query-as-string/@id)}</history>
            <query-tabs>advanced-search-form</query-tabs>
        </data>        
    return
        <li><a onclick="tamboti.apis.advancedSearchWithData({json:contents-to-json($advanced-search-data)})" href="#">{biblio:xml-query-to-string($query-as-string)}</a></li>
}
</ul>
