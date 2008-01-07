use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Win32::GUIRobot::Easy',
    VERSION_FROM      => 'lib/Win32/GUIRobot/Easy.pm', # finds $VERSION
    PREREQ_PM         => { 'Win32::GUIRobot' => '0.05', 'Win32::Clipboard' => '0.5201' }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Win32/GUIRobot/Easy.pm', # retrieve abstract from module
       AUTHOR         => 'zoffix <cpan@zoffix.com>') : ()),
);
