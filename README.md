Auto Gentoo
===========

********************Just Started. Don't even try yet!! Does not work!*********

Auto Gentoo is free software distributed under the terms of the MIT license.
For license details, see LICENSE.

WARNING:
THIS MAY BREAK AT NY TIME DUE TO CHANGES IN GENTOO. PLEASE TEST BEFORE USING IN PRODUCTION.

ALSO THE CONFIG FILES ARE IN BASH FORMAT SO ONLY USE ONE'S YOU CREATE. I PUT SOME FILTERS IN HOWEVER THERE ARE WAYS AROUND THIS. IF YOU USE SOMEONE ELESES, PLEASE READ THROUGH IT. OUR CONFIG's ARE NAME="VALUE" FORMAT.

Bash script for a more automated Gentoo Linux installation

"Auto Gentoo" is a bash script that installs Gentoo Linux from a stage3 tarball. We are using bash and the list of required programs to free up which distro you use to install with.

The overall procedure is either unattended, everything is handled by script, or fill a you go, user required. These steps are enabled or disabled according to a "profile" file.

Profile is a simple text file which has the necessary options, settings etc. for the installation. (Profile must be named as "profile") With a proper profile, it is possible to have a basic system (without X) or a ready to use Openbox desktop with a few key strokes.
