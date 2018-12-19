xquery version "3.1";

declare namespace httpclient = "http://exist-db.org/xquery/httpclient";

let $url := "http://kjc-ws2.kjc.uni-heidelberg.de:8650/exist/apps/BOM.xml"
let $encoding := "UTF-8"

let $responses := httpclient:get($url, false(), ())
let $string := $responses/httpclient:body
(:let $string := replace($string, "\\uFFFF", ""):)

(:return contains($string, "\uFFFF"):)
return util:parse($string)