xquery version "3.0";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

let $data := request:get-data()

let $uuid := data($data//@xml:id)

let $records := collection("/resources/services/repositories/local/organisations")//tei:listOrg

let $insert-data := update insert $data into $records 

return 
    if ($records/*[@*:id = $uuid])
    then (<result>true</result>)
    else (<result>false</result>)