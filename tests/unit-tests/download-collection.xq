xquery version "3.0";
import module namespace functx = "http://www.functx.com";

let $collection := xmldb:encode-uri('/data/users/editor/Grabung_KMH_Kastellweg')
let $date := current-dateTime()

let $zip := compression:zip($collection, true())
return response:stream-binary($zip, "application/zip", functx:substring-after-last($collection, "/") || "_" || $date || ".zip")

