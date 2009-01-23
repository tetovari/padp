WinMerge Portable Launcher 1.6.10
=================================
Copyright 2007-2008 Ryan McCue
Copyright 2004-2008 John T. Haller

Website: http://PortableApps.com/WinMergePortable

This software is OSI Certified Open Source Software.
OSI Certified is a certification mark of the Open Source Initiative.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.


About WinMerge Portable
=========================
The WinMerge Portable Launcher allows you to run WinMerge from a removable drive
whose letter changes as you move it to another computer.  The program can be
entirely self-contained on the drive and then used on any Windows computer.


License
=======
This code is released under the GPL.  Within the FirefoxPortableSource directory
you will find the code (FirefoxPortable.nsi) as well as the full GPL license
(License.txt).  If you use the launcher or code in your own product, please give
proper and prominent attribution.


Installation / Directory Structure
==================================
By default, the program expects this directory structure:

-\ <--- Directory with WinMergePortable.exe
	+\App\
		+\WinMerge\
	+\Data\
		+\settings\


WinMergePortable.ini Configuration
====================================
The WinMerge Portable Launcher will look for an ini file called
WinMergePortable.ini (read the previous section for details on placement).  If
you are happy with the default options, it is not necessary, though.  The INI
file is formatted as follows:

[WinMergePortable]
AdditionalParameters=
DisableSplashScreen=false

The AdditionalParameters entry allows you to pass additional commandline
parameter entries to WinMergeU.exe.  Whatever you enter here will be appended
to the call to WinMergeU.exe.

The DisableSplashScreen entry allows you to run the WinMerge Portable Launcher
without the splash screen showing up.  The default is false.