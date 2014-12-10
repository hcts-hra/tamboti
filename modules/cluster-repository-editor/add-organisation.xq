xquery version "3.0";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $data := request:get-data()

let $uuid := data($data//@xml:id)

let $records-collection := xs:anyURI("/resources/services/repositories/local/users/" || xmldb:get-current-user() || "/organisations")

let $records := collection($records-collection)//tei:listOrg

let $insert-data := update insert $data into $records 

return 
    if ($records/*[@*:id = $uuid])
    then (<result>true</result>)
    else (<result>false</result>)
