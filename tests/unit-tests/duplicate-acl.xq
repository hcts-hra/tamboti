xquery version "3.0";

import module namespace security="http://exist-db.org/mods/security" at "../../modules/search/security.xqm";

sm:add-group-ace(xs:anyURI("/resources/users/editor/old"), "biblio.users", true(), "rwx"),


sm:get-permissions(xs:anyURI("/resources/users/editor/old"))
