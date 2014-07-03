xquery version "3.0";

let $current-user := "http://" || request:get-server-name() || "/" || xmldb:get-current-user()


return
    <TEI xmlns="http://www.tei-c.org/ns/1.0">
        <teiHeader>
            <fileDesc>
                <titleStmt>
                    <title />
                    <author ref="{$current-user}" />
                </titleStmt>
                <editionStmt>
                    <edition>
                        <date when="{current-dateTime()}" />
                        <persName ref="{$current-user}" role="creator" />
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
    