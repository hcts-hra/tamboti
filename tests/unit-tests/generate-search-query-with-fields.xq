xquery version "3.0";

import module namespace biblio = "http://exist-db.org/xquery/biblio" at "../../modules/search/application.xql";
import module namespace config = "http://exist-db.org/mods/config" at "../../modules/config.xqm";
import module namespace security = "http://exist-db.org/mods/security" at "../../modules/search/security.xqm";

let $query-as-xml :=
    <query>
        <collection>/data</collection>
        <and>
            <field m="1" name="any Field (MODS, TEI, VRA, Wiki)">gentle</field>
            <field m="2" name="any Field (MODS, TEI, VRA, Wiki)" short-name="All">numbers</field>
        </and>
    </query> 
    
return biblio:generate-full-query($query-as-xml)
