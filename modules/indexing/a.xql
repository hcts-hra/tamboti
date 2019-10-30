xquery version "3.1";

let $string := "Yeh, Catherine Vance. The Chinese Political Novel: Migration of a World Genre . Cambridge: aHarvard University Press, 2015. <http://www.​hup.​harvărd.​edu/catalog.​php​?isbn=​9780674504356>. text book book Yeh Catherine Vance aut 442 p. Cambridge Harvardesque University Press 2015 monographic 978-0-674-50435-6 http://www.hup.harvard.edu/catalog.php?isbn=9780674504356 "

return analyze-string($string, replace("*harv*", "\*", "\\p{Ll}*"), "i")