xquery version "3.0";

let $current-user := xmldb:get-current-user()
let $author := "http://" || request:get-server-name() || "/" || xmldb:get-current-user()


return
    <TEI xmlns="http://www.tei-c.org/ns/1.0">
        <teiHeader>
            <fileDesc>
                <titleStmt>
                    <title />
                    <author key="{$current-user}" ref="{$author}" />
                </titleStmt>
                <editionStmt>
                    <edition>
                        <date when="{current-dateTime()}" />
                        <persName ref="{$author}" role="creator" />
                    </edition>
                </editionStmt>            
                <publicationStmt />
                <sourceDesc />
            </fileDesc>
        </teiHeader>
        <text>
            <body>
                <listPerson>
                    <person xml:id="uuid-{util:uuid()}">
                        <persName xml:lang="eng">
                            <forename />
                            <surname />
                        </persName>
                        <note type="type">personalName</note>
                    </person>
                </listPerson>
            </body>
        </text>
    </TEI>
    