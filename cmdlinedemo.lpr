program cmdlinedemo;

//**********************************************************************************************************************************
//
//  Demo program to show how to use the 'getoptions' unit
//
//  Copyright: (C) 2021, Zsolt Szakaly
//
//  This source is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as
//  published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.
//
//  This code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
//
//  A copy of the GNU General Public License is available on the World Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can
//  also obtain it by writing to the Free Software Foundation, Inc., 51 Franklin Street - Fifth Floor, Boston, MA 02110-1335, USA.
//
//**********************************************************************************************************************************
//
//  Change log:
//    22/10/2021 Added an example to show the usage of the last (optional) parameter to omit erroneous options
//
//  Description
//
//  It creates an array of option definitions, and calls multiple times with different parameters the CommandLineOptions function
//  The result given back as a tOptionResults array is printed
//
//  For all other details, please see the description and the record explanation in the 'getoptions' unit
//
//  To run, try something like this (and understand the result):
//    ./cmdlinedemo -ffilename -fs -sf --feedbackswitch=value -? -g nonopt -- -f
//
//**********************************************************************************************************************************

{$mode objfpc}
{$H+}

uses
  getoptions;

var
  Switch : integer = 0;

const
  OptionDefinitions : tOptionDefinitions = (
    (ShortOptions:('h','?');LongOptions:('help','manual');ArgumentOption:aoNotAllowed;ReturnValue:'Help';FlagPointer:nil;FlagValue:0),
    (ShortOptions:('a');LongOptions:('add');ArgumentOption:aoMandatory;ReturnValue:'MandatoryAdd';FlagPointer:nil;FlagValue:0),
    (ShortOptions:('f');LongOptions:('addfile');ArgumentOption:aoOptional;ReturnValue:'AddFile';FlagPointer:nil;FlagValue:0),
    (ShortOptions:();LongOptions:();ArgumentOption:aoNotAllowed;ReturnValue:'Non-option';FlagPointer:nil;FlagValue:0),
    (ShortOptions:('s');LongOptions:('switch');ArgumentOption:aoNotAllowed;ReturnValue:'';FlagPointer:@Switch;FlagValue:111),
    (ShortOptions:();LongOptions:('feedbackswitch');ArgumentOption:aoNotAllowed;ReturnValue:'FeedbackSwitch';FlagPointer:@Switch;FlagValue:222)
    );
var
  CmdLineParameters : tOptionResults;
  i:integer;

procedure PrintResults;
  begin
  Writeln('No             ReturnValue DefinitionIndex InputIndex    OK          Option        Argument');
  for i:= 0 to length(CmdLineParameters) -1 do
    with CmdLineParameters[i] do
      writeln(i:2,ReturnValue:24,DefinitionIndex:16,InputIndex:11,OK:6,Option:16,Argument:16);
  Writeln('SIWTCH = ',Switch);
  Writeln;
  end;

begin

Writeln('Command line options in the classic order, i.e. starting with the real options (including unknown and incorrect) '+
    'followed by the non-option values, both in their input order.');
CmdLineParameters := CommandLineParameters(OptionDefinitions,soClassic);
PrintResults;

Writeln('Command line options in the order of their definition (starting with the unknown options). Options and Non-options are '+
    'mixed together.');
CmdLineParameters := CommandLineParameters(OptionDefinitions,soDefinition);
PrintResults;

Writeln('Command line options in the order of their ReturnValue (starting with the unknown options, i.e. ReturnValue = '''').');
CmdLineParameters := CommandLineParameters(OptionDefinitions,soReturnValue);
PrintResults;

Writeln('Command line options in the order of their Input.');
CmdLineParameters := CommandLineParameters(OptionDefinitions,soInput);
PrintResults;

Writeln('Command line options in the order of their Input, not including erroneous options.');
CmdLineParameters := CommandLineParameters(OptionDefinitions,soInput,false);
PrintResults;

end.
