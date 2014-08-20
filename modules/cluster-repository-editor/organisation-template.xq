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
                <listOrg>
                    <org xml:id="uuid-{util:uuid()}">
                    	<orgName xml:lang="eng" />
                    	<note type="type">corporateName</note>
                    </org>
                </listOrg>
            </body>
        </text>
    </TEI> 
