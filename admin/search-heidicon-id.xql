xquery version "3.0";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";
declare namespace vra-ext="http://exist-db.org/vra/extension";

declare option exist:serialize "method=xml media-type=application/xml indent=yes";

let $id:= request:get-parameter("id", ())
return
    if (empty($id)) then
        "Keine id angegeben"
    else
        <result>
            {
                collection("/resources/")//vra:vra[.//vra-ext:value=$id]
            }
        </result>

