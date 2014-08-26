### Notes for Developers 

Icon stock is from - http://www.famfamfam.com/lab/icons/silk/

### Installation

* cd into the tamboti directory and call ant; a file, tamboti-X.XX.xar, is created.
* log in as admin to eXist, go to the Package Reposistory, choose tamboti-X.XX.xar and upload it.
* click "Install"
* copy "modules/config.default.xqm" to "modules/config.xqm" 
* copy "modules/config/services.default.xml" to "modules/config/services.xml"
* and modify both for your needs. 
* access tamboti at <http://localhost:8080/exist/apps/library/> or <http://localhost:8080/exist/apps/tamboti/>.

* Note that in $EXIST_HOME/webapp/WEB-INF/controller-config.xml, the following mappings have to be set
	<root pattern="/apps/library" path="xmldb:exist:///db/tamboti"/>
	<root pattern="/apps/tamboti" path="xmldb:exist:///db/tamboti"/>
before
	<root pattern="/apps" path="xmldb:exist:///db"/>

### Dependencies:

* build eXist with modules "image" and "contentextraction" and enable them in $EXIST_HOME/conf.xml
* eXist ImageMagick Plugin by ZwoBit https://github.com/zwobit/imagemagick.xq
* functx EXPath package - can be found in the eXist's public repo.
* xsltforms EXPath package - can be found in the eXist's public repo.