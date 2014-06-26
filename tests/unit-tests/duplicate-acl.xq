xquery version "3.0";

sm:add-group-ace(xs:anyURI("/resources/users/editor/old"), "biblio.users", true(), "rwx"),
sm:get-permissions(xs:anyURI("/resources/users/editor/old"))
