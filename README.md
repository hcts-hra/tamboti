Notes for Developers 

Icon stock is from - http://www.famfamfam.com/lab/icons/silk/


### Installation

Build the xar pakage according to the building section below, along with the dependencies mentioned below, and install all these xar-s in eXist.

Access tamboti at <http://localhost:8080/exist/apps/library/> or <http://localhost:8080/exist/apps/tamboti/>.


### Building with maven
N. B.  Maven 3.1.1+ is needed.
  
* For developer test instance of tamboti, use "clean package -Pdeveloper-test-build".
* For general (stable) test instance of tamboti, use "clean package -Pgeneral-test-build".
* For production instance of tamboti, use "clean package -Pgeneral-production-build".
* For Cluster Asia and Europe... instance of tamboti, use "clean package -Pcluster-production-build".

### Dependencies
* dropDownListCheckbox - can be found at https://github.com/claudius108/jquery.dropDownListCheckbox. It has to be build with maven and installed as xar.