<?php

if (isset($_FILES["myFile"]) && $_FILES["myFile"]["error"] == UPLOAD_ERR_OK) {

    $UploadDirectory    = '/home/claudius/workspaces/web-sites/multiple-uploader/upload/'; //specify upload directory ends with / (slash)
      
    //Is file size is less than allowed size.
    if ($_FILES["myFile"]["size"] > 5242880) {
        die("File size is too big!");
    }
   
    //allowed file type Server side check
    switch(strtolower($_FILES['myFile']['type']))
        {
            //allowed file types
            case 'image/png':
            case 'image/gif':
            case 'image/jpeg':
            case 'image/pjpeg':
            case 'text/plain':
            case 'text/html': //html file
            case 'application/x-zip-compressed':
            case 'application/pdf':
            case 'application/msword':
            case 'application/vnd.ms-excel':
            case 'video/mp4':
                break;
            default:
                die('Unsupported File!'); //output error
    }
    
    echo $_FILES['myFile']['name']."\n";
   
	if (move_uploaded_file($_FILES['myFile']['tmp_name'], $UploadDirectory.$_FILES["myFile"]['name'])) {
	    echo "Uploaded!";
	} else {
	   echo "File was not uploaded!";
	}
   
}
else
{
    die('Something wrong with upload! Is "upload_max_filesize" set correctly?');
}

?>