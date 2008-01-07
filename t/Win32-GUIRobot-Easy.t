# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-GUIRobot-Easy.t'

use Test::More tests => 1;
BEGIN { use_ok('Win32::GUIRobot::Easy') };


