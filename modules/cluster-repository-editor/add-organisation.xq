xquery version "3.0";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $data := request:get-data()

let $uuid := data($data//@xml:id)

let $parent-collection := "/resources/services/repositories/local/organisations/users"

let $records-collection := xs:anyURI($parent-collection || "/" || xmldb:get-current-user())

let $create-records-collection :=
    if (xmldb:collection-available($records-collection))
    then ()
    else xmldb:create-collection($parent-collection, xmldb:get-current-user())

let $records := collection($records-collection)//tei:listOrg

let $insert-data := update insert $data into $records 

return 
    if ($records/*[@*:id = $uuid])
    then (<result>true</result>)
    else (<result>false</result>)
