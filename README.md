Notes for Developers 

Icon stock is from - http://www.famfamfam.com/lab/icons/silk/


### Installation

* Build the xar pakage according to the building section below, along with the dependencies mentioned below, and install all these xar-s in eXist.
* Modify "modules/config.default.xqm" and "modules/configuration/services.xml" according to your needs. 
* Access tamboti at <http://localhost:8080/exist/apps/tamboti/>.


### Building with maven
N. B.  Maven 3.1.1+ is needed.
  
* For production instance of tamboti, use "clean package -Pgeneral-production-build".
* For test instance of tamboti, use "clean package -Pgeneral-test-build".
* For Cluster Asia and Europe... production instance of tamboti, use "clean package -Pcluster-production-build".  
* For Cluster Asia and Europe... test instance of tamboti, use "clean package -Pcluster-test-build".

### Dependencies
* eXist’s content extraction and image modules.
* eXist ImageMagick Plugin by ZwoBit https://github.com/zwobit/imagemagick.xq
