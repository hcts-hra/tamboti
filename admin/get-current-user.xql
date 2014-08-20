xquery version "3.0";

declare namespace mods="http://www.loc.gov/mods/v3";
declare namespace vra = "http://www.vraweb.org/vracore4.htm";

<users>
    <xmldb>
        {
            xmldb:get-current-user()
        }
    </xmldb>
    <session>
        <eXist_xmldb_user>
            {
                session:get-attribute("_eXist_xmldb_user")
            }
        </eXist_xmldb_user>
        <biblio_user>
            {
                session:get-attribute("biblio.user")
            }
        </biblio_user>
    </session>
</users>