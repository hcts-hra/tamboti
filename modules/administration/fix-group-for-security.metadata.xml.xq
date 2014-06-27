xquery version "3.0";

for $file in collection("/resources/users")[ends-with(document-uri(.), 'security.metadata.xml')]
let $file-path := document-uri($file)
return
    (
        sm:get-permissions($file-path),
        sm:chgrp($file-path, "biblio.users"),
        sm:get-permissions($file-path)
    )