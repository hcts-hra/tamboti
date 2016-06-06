xquery version "3.0";

import module namespace biblio = "http://exist-db.org/xquery/biblio" at "../../modules/search/application.xql";

let $query-as-xml :=
    <query>
        <collection>/data/commons</collection>
    </query>
    
return biblio:generate-full-query($query-as-xml)
