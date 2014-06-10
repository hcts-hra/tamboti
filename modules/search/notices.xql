xquery version "1.0";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace response="http://exist-db.org/xquery/response";

if(request:get-parameter("action",()))then
    if(request:get-parameter("action", ()) eq "seen-notices")then
        session:set-attribute("seen-notices", true())
    else
        response:set-status-code(400)
else
    response:set-status-code(400)