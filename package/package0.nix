let 
    snowball = import (builtins.fetchurl "https://raw.githubusercontent.com/jeff-hykin/snowball/29a4cb39d8db70f9b6d13f52b3a37a03aae48819/snowball.nix");
in 
    (snowball "https://raw.githubusercontent.com/jeff-hykin/snowball/3df028e5d9e92dbe077ce34f6907da852e61895a/").package0