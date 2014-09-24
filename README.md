Notes for Developers 

Icon stock is from - http://www.famfamfam.com/lab/icons/silk/


### Installation

* Build the xar pakage according to the building section below, along with the dependencies mentioned below, and install all these xar-s in eXist.
* Copy "modules/config.default.xqm" to "modules/config.xqm".
* Copy "modules/configuration/services.default.xml" to "modules/configuration/services.xml".
* Modify both of the above files according to your needs.
* Access tamboti at <http://localhost:8080/exist/apps/library/> or <http://localhost:8080/exist/apps/tamboti/>.


### Building with maven
N. B.  Maven 3.1.1+ is needed.
  
* For developer test instance of tamboti, use "clean package -Pdeveloper-test-build".
* For general (stable) test instance of tamboti, use "clean package -Pgeneral-test-build".
* For production instance of tamboti, use "clean package -Pgeneral-production-build".
* For Cluster Asia and Europe... instance of tamboti, use "clean package -Pcluster-production-build".

### Dependencies
* dropDownListCheckbox - https://github.com/claudius108/jquery.dropDownListCheckbox. It has to be build with maven and installed as xar.
* functx EXPath package - can be found in the eXist's public repo.
* xsltforms EXPath package - can be found in the eXist's public repo.
* eXist’s content extraction and image modules.
* eXist ImageMagick Plugin by ZwoBit https://github.com/zwobit/imagemagick.xq
