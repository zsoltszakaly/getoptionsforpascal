unit getoptions;

//**********************************************************************************************************************************
//
//  Pascal function to analyse the command line parameters
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
//    22/10/2021 Added a new (optional) parameter to omit erroneous options. The default value is to include all options. Changing
//               it to false, means to leave out all unexpected and incorrectly specified options
//    22/10/2021 In case of sorting by ReturnValue or by DefinitionOrder, a secondary sorting is added to sort by input order if the
//               main sorting criterium is the same for two (or more) options
//
//  Description
//
//  USER SIDE
//
//  There are three different types of options that can be entered in a command line for a program:
//    - Short option
//    - Long option
//    - Non-option
//
//  The Short and Long options can have attributes, but non-options cannot have. Three options can be specified to define how the
//  option accepts attributes:
//    - Mandatory
//    - Optional
//    - Not allowed
//
//  Short options
//
//  Short options start with a '-' followed by one character options. Multiple short options can be combined in one block, like
//  -abc.
//
//  If a short option has a mandatory argument, it can be used two different ways:
//    -aargument
//    -a argument
//  It is not allowed to use -a=argument. In this case the argument returned is '=argument'.
//
//  If a short option has an optional argument, it can be used two different ways (the first has no argument):
//    -a
//    -aargument
//
//  If a short option is specified as option aoNotAllowed, it cannot have an argument:
//    -aargument is understood as a set of options, 'a','a','r', etc.
//    -a=X is understood as a set of options, 'a','=','X'
//    -a arg is understood as a short option 'a' and a non-option arg
//
//  It is allowed to combine short options with not allowed options and another option with optional or mandatory arguments. If e.g.
//  'a'is designed that it cannot have an argument, but 'b' has a mandatory argument, then:
//    -abc is understood as 'a' without argument and 'b' with argument 'c'
//    -bac is understood as 'b' with argument 'ac'
//
//  Long options
//
//  Long options start with '--' followed by a variable length option.
//
//  If a long option has a mandatory argument, it can be used two different ways:
//    --file filename.dat
//    --file=filename.dat
//
//  If a long option has an optional argument, it can also be used two ways, e.g.:
//    --sort
//    --sort=descending
//
//  The user is allowed to give only a fraction of the long option name, if it can be identified. If there are two long options,
//  file and filetype, then:
//    --fil=filename.dat is allowed as it can mean both file and filetype. On the other hand:
//    --file=filename.dat is correct, becuase it is identical to one long option name and that is used even if a second long option
//      starts with the same letters.
//
//  Non-options
//
//  Non-options normally do not start with '-'. If in the command line there is an empty option, either '-' or '--', then all
//  subsequent parameters are considered non-options.
//
//  Non-options cannot have parameters.
//
//  DEVELOPER SIDE
//
//  Specification of the expected options
//
//  The expected options are handed over to the function in one array of tOptionDefinition records. For the fields of the record,
//  please read the tOptionDefinition below.
//
//  Result
//
//  The main result of the function is an array with the found options. See the specification of tOptionResult.
//  The sequence of the result records is sorted, depending on the second parameter of the function. There are four options:
//    soDefinition : the records are sorted in the same sequence as their deinition in the tOptionDefinitions
//    soReturnValue : the records are sorted as per their ReturnValue
//    soInput : the records are sorted as per the user input
//    soClassic : First Short and Long options are given back in the input sequence followed by the non-options also in input order
//  No record is generated for options with ReturnValue = ''
//  Records with ReturnValue = '' is returned for unknown options
//
//  Flags
//
//  In the option definition pointers can also be assigned in FlagPointer. If the option is found, then FlagPointer^ is set to
//  the value specied in FlagValue.
//  Flags are set in the order of the occurence of the options, i.e. if the same FlagPointer is assigned to different options then
//  the value will show the FlagValue of the last used option.
//
//**********************************************************************************************************************************

{$mode objfpc}
{$H+}

interface

const
  OptionChar : Char = '-';

type
  // Basic types derived from standard pascal types
  tChars = array of Char;
  tStrings = array of string;

  // Enumerated types used when the function is called
  tArgumentOptions     = (aoMandatory, aoOptional, aoNotAllowed);
      // (the names are self explanatory)
  tSortingOptions      = (soDefinition, soReturnValue, soInput, soClassic);
      // Sets the sequence in the result:
      //   soDefinition  : in the order how the given option was defined
      //   soReturnValue : in the order of the return value of the option
      //   soInput       : in the same order, including Non-Options, as the user input them
      //   soClassic     : in the same order as the user input the options and then followed by the Non-Options also in input order

  // The structure used to define one parameter
  tOptionDefinition = record
      // One option can have multiple Short and Long option identifiers (see the first two fields)
      // If BOTH are EMPTY, the option relates to the non-options
      // If two (or more) definitions are empty, only the first one is used
    ShortOptions       : tChars;
      // One option can have multiple assigned Char (Short option) codes, typical example is 'h' and '?'
      // The same Char code might appear for different options, but only the first one is used
    LongOptions        : tStrings;
      // One option can have multiple assigned String codes (Long option)
      // The same Long option can also appear multiple times, but only the first one is used
    ArgumentOption     : tArgumentOptions;
      // The field specifies whether arguments are needed for the option or not
    ReturnValue        : string;
      // This is the value the ReturnValue field of the result stores if the given option appears
      // If the ReturnValue = '' the option is not included in the result, but it is not an error
      // ReturnValue = '' is typically used if the option changes a flag and hence no more processign is needed
      // ReturnValue = '' can also be used to omit certain options, e.g. for compatibility reasons
      // Different options can have the same ReturnValue
    FlagPointer        : pInteger;
      // If FlagPointer <> nil, then FlagPointer^ := FlagValue is set when the option is found
      // The same pointer can be used for different options also with different FlagValue-s
      // The Flags are set in the order of user input, i.e. the FlagValue of the last used option will appear in FlagPointer^
    FlagValue          : integer;
      // The value set to the FlagPointer^
      // Most frequently the flag is used as a Boolean value and so FlagValue = 1 but any other integer is allowed.
    end;
  // The array to store ALL the allowed options
  tOptionDefinitions = array of tOptionDefinition;

  // The structure used to return the result of the CommandLineParameters function
  tOptionResult = record
      // For every option and non-option, found among the command line parameters a record is returned, EXCEPT
      // those options that have a ReturnValue = ''
    ReturnValue        : string;
      // The return value as per the first option definition where the found option is listed (Short or Long)
      // For options not defined, the ReturnValue = '' and OK = false
      // ATTENTION: ReturnValue = '' is therefore NOT in use when in the definition record ReturnValue = '', the latter is not
      // returned at all
      // The result array can automatically be sorted as per the ReturnValue
    DefinitionIndex    : integer;
      // This index points to the tOptionDefinition record in the tOptionDefinitions array, where the option found is first
      // specified
      // If the option is not specified, the DefinitionIndex = -1 and OK = false
      // Non-options (if specified with an empty list of both Short and Long options) return a normal DefinitionIndex
      // The result array can automatically be sorted as per the DefinitionIndex
    InputIndex         : integer;
      // This index points to the position in the sequence of options and non-options in the command line parameters
      // The result array can automatically be sorted as per the InputIndex
    OK                 : boolean;
      // Indicates if the found option was used as per the specification
      // Unknown option, ambiguos Long option name fraction, Option with missing mandatory argument and a long option with an
      // unexpected = sign have OK = false
    Option             : string;
      // The literal format how the option was found
      // This is useful if an option has short and long version or even multiple ones
      // Also it returns the literal format when a Long option is identified from a shorter fraction
      // For non-options the value is returned here AND in the Argument field as well
    Argument           : string;
      // The argument given for the option
      // If no argument is given then Argument = ''; for aoOptional it is OK, for aoMandatory it is OK = false
      // For long options, it is possible to have an =argument even if aoNotAllowed; that argumant is also returned but OK = false
      // For non-options the value is returned here AND in the Option field as well
    end;
  // The array to store ALL the found options (except the ones specified with ReturnValue = '')
  tOptionResults = array of tOptionResult;

// The main function
function CommandLineParameters(const aOptions : tOptionDefinitions; aSorting : tSortingOptions = soClassic;
    aReturnAll : boolean = true) : tOptionResults;

implementation

uses
  quicksort;

type
  // Identify what type of option is being processed
  tOptionMode = (omShortOption, omLongOption, omNonOption, omNonOptions);
    // The last value indicates that from that point on all options are non-options (i.e. following an empty - or an empty --)

// Two functions used for sorting
function CompareDefinitionIndex(const a1, a2) : integer;
  var
    r1 : tOptionResult absolute a1;
    r2 : tOptionResult absolute a2;
  begin
  if r1.DefinitionIndex = r2.DefinitionIndex then
    begin
    if r1.InputIndex = r2.InputIndex then result := 0
    else if r1.InputIndex < r2.InputIndex then result := -1
    else result := 1;
    end
  else
    begin
    if r1.DefinitionIndex < r2.DefinitionIndex then result := -1
    else result := 1;
    end;
  end;
function CompareReturnValue(const a1, a2) : integer;
  var
    r1 : tOptionResult absolute a1;
    r2 : tOptionResult absolute a2;
  begin
  if r1.ReturnValue = r2.ReturnValue then
    begin
    if r1.InputIndex = r2.InputIndex then result := 0
    else if r1.InputIndex < r2.InputIndex then result := -1
    else result := 1;
    end
  else
    begin
    if r1.ReturnValue < r2.ReturnValue then result := -1
    else result := 1;
    end;
  end;
// The main function, split into sub-function for better readibility
function CommandLineParameters(const aOptions : tOptionDefinitions; aSorting : tSortingOptions = soClassic;
    aReturnAll : boolean = true) : tOptionResults;
  var
    NonOptions : tOptionResults = nil;
      // A temporary array to store non-options for soClassic
    OptionMode : tOptionMode;
      // The type of the option being procesed
    ParamIndex : integer = 1;
      // The index in ParamStr, being processed
    ParamProcessed : string;
      // A temporary string holding the Param (or its unprocessed part) being processed
  // When an option is found, it is added to the relevant array
  procedure AddResult(aReal : boolean; aReturnValue : string; aDefinitionIndex : integer; aOK : boolean;
      aOption : string; aArgument : string);
    begin
    // Decide if Result is to be reported, or not
    if (not aOK) and (not aReturnAll) then
      exit;
    // Set the flag if applicable
    if (aDefinitionIndex <> -1) and
       (aOptions[aDefinitionIndex].FlagPointer <> nil) then
      begin
      try
        aOptions[aDefinitionIndex].FlagPointer^ := aOptions[aDefinitionIndex].FlagValue;
      except
        aOK := false;
        end;
      end;
    // Do not return intentional empty code
    if aOK and (aReturnValue = '') then
      exit;
    // Add to the relevant array
    if aReal or (aSorting = soDefinition) or (aSorting = soReturnValue) or (aSorting = soInput) then
      begin // real (i.e. not non-option) options are always added to the main array, and also non-options if
            // not in soClassic mode.
      SetLength(Result, length(Result) + 1);
      with Result[length(Result) - 1] do
        begin
        ReturnValue := aReturnValue;
        DefinitionIndex := aDefinitionIndex;
        InputIndex := length(Result) + length(NonOptions) - 1;
        OK := aOK;
        Option := aOption;
        Argument := aArgument;
        end; // with
      end // if
    else
      begin // anything not real (i.e. non-option) in a sorting option soClassic (and other undefined value)
      SetLength(NonOptions, length(NonOptions) + 1);
      with NonOptions[length(NonOptions) - 1] do
        begin
        ReturnValue := aReturnValue;
        DefinitionIndex := aDefinitionIndex;
        InputIndex := length(Result) + length(NonOptions) - 1;
        OK := aOK;
        Option := aOption;
        Argument := aArgument;
        end; // with
      end; // else
    end; // AddResult
  // When a new CmdLine parameter is started it decides what sort of option it is
  procedure DecideOptionMode;
    begin
    // Decide what option mode is found
    if OptionMode = omNonOptions then
      exit; // no need to further check, omNonOptions is valid for the rest of the parameters
    OptionMode := omNonOption;
    if ParamProcessed[1] = OptionChar then
      begin // first - makes it a short option
      OptionMode := omShortOption;
      Delete(ParamProcessed,1,1);
      end;
    if (length(ParamProcessed) > 0) and (ParamProcessed[1] = OptionChar) then
      begin // second - makes it a long option
      OptionMode := omLongOption;
      Delete(ParamProcessed,1,1);
      end;
    if length(ParamProcessed) = 0 then
      begin // an empty - or -- makes it a permanent non-option list going forward
      OptionMode := omNonOptions;
      end;
    end; // DecideOptionMode
  // Find the short index in the definitions
  function ShortOptionIndex(aOption : Char) : integer;
    var
      i,j : integer;
    begin
    result := -1;
    for i := 0 to length(aOptions) - 1 do
      for j:= 0 to length(aOptions[i].ShortOptions) - 1 do
        if aOptions[i].ShortOptions[j] = aOption then
          begin
          result := i;
          exit;
          end;
    end; // ShortOptionIndex
  // Identified an option as a short option, being processed
  procedure ProcessAShortOption;
    var
      Option : Char;
      OptionIndex : integer;
    begin
    Option := ParamProcessed[1];
    Delete(ParamProcessed,1,1);
    OptionIndex := ShortOptionIndex(Option);
    if OptionIndex = -1 then
      begin
      AddResult(true, '', OptionIndex, false, Option, '');
      exit;
      end;
    case aOptions[OptionIndex].ArgumentOption of
      aoMandatory:
        begin
        if length(ParamProcessed) > 0  then
          begin // the mandatory parameter is written next to the option character
          AddResult(true, aOptions[OptionIndex].ReturnValue, OptionIndex, true, Option, ParamProcessed);
          ParamProcessed := '';
          exit;
          end;
        if ParamIndex < ParamCount -1 then
          begin // there is a next param
          inc(ParamIndex);
          AddResult(true, aOptions[OptionIndex].ReturnValue, OptionIndex, true, Option, ParamStr(ParamIndex));
          exit;
          end;
        // error, missing mandatory parameter
        AddResult(true, aOptions[OptionIndex].ReturnValue, OptionIndex, false, Option, '');
        exit;
        end; // aoMandatory
      aoOptional:
        begin
        AddResult(true, aOptions[OptionIndex].ReturnValue, OptionIndex, true, Option, ParamProcessed);
        ParamProcessed := '';
        exit;
        end; // aoOptional
      else // normally only aoNotAllowed
        begin
        // the normal way, no argument
        AddResult(true, aOptions[OptionIndex].ReturnValue, OptionIndex, true, Option, '');
        end; // else (aoNotAllowed)
      end; // case
    end;
  // Find the long index in the definitions
  function LongOptionIndex(aOption : string) : integer;
    var
      i,j : integer;
    begin
    result := -1;
    // First checking for perfect match
    for i := 0 to length(aOptions) - 1 do
      for j:= 0 to length(aOptions[i].LongOptions) - 1 do
        if aOptions[i].LongOptions[j] = aOption then
          begin
          result := i;
          exit;
          end;
    // If not found, checking the partial match
    for i := 0 to length(aOptions) - 1 do
      for j:= 0 to length(aOptions[i].LongOptions) - 1 do
        if pos(aOption,aOptions[i].LongOptions[j]) = 1 then
          begin // A potential match found
          if result = -1 then
            begin
            result := i; // recorded as a match
            end
          else
            begin
            result := -1;
            exit;
            end;
          end;
    end; // LongOptionIndex
  // Identified an option as a long option, being processed
  procedure ProcessALongOption;
    var
      Option : string;
      OptionIndex : integer;
      EqualPosition : integer;
    begin
    EqualPosition := pos('=',ParamProcessed);
    if EqualPosition > 0 then
      begin
      Option := copy(ParamProcessed,1,EqualPosition-1);
      ParamProcessed := Copy(ParamProcessed,EqualPosition); // still including the equal sign
      end
    else
      begin
      Option := ParamProcessed;
      ParamProcessed := '';
      end;
    OptionIndex := LongOptionIndex(Option);
    if OptionIndex = -1 then
      begin
      if length(ParamProcessed) > 0  then
        Delete(ParamProcessed,1,1); // remove the equal sign and use the rest
      AddResult(true, '', OptionIndex, false, Option, ParamProcessed);
      ParamProcessed := '';
      exit;
      end;
    case aOptions[OptionIndex].ArgumentOption of
      aoMandatory:
        begin
        if length(ParamProcessed) > 0  then
          begin // the mandatory parameter is written after an equal sign
          Delete(ParamProcessed,1,1);
          AddResult(true, aOptions[OptionIndex].ReturnValue, OptionIndex, true, Option, ParamProcessed);
          ParamProcessed := '';
          exit;
          end;
        if ParamIndex < ParamCount -1 then
          begin // there is a next param
          inc(ParamIndex);
          AddResult(true, aOptions[OptionIndex].ReturnValue, OptionIndex, true, Option, ParamStr(ParamIndex));
          exit;
          end;
        // error, missing mandatory parameter
        AddResult(true, aOptions[OptionIndex].ReturnValue, OptionIndex, false, Option, '');
        exit;
        end; // aoMandatory
      aoOptional:
        begin
        if length(ParamProcessed) > 0  then
          Delete(ParamProcessed,1,1); // remove the equal sign and use the rest
        AddResult(true, aOptions[OptionIndex].ReturnValue, OptionIndex, true, Option, ParamProcessed);
        ParamProcessed := '';
        exit;
        end; // aoOptional
      else // normally only aoNotAllowed
        begin
        if length(ParamProcessed) > 0  then
          begin
          Delete(ParamProcessed,1,1); // remove the equal sign and use the rest, although should not be there
          AddResult(true, aOptions[OptionIndex].ReturnValue, OptionIndex, false, Option, ParamProcessed);
          ParamProcessed := '';
          exit;
          end;
        // the normal way, no argument
        AddResult(true, aOptions[OptionIndex].ReturnValue, OptionIndex, true, Option, '');
        end; // else (aoNotAllowed)
      end; // case
    end;
  // Find the index for non-options in the definitions
  //   Theoretically it could be found only once and used as a variable to save run-time, but the gain is so
  //   little that I rather kept the same logic as for short and long options
  function NonOptionIndex : integer;
    var
      i : integer;
    begin
    result := -1;
    for i := 0 to length(aOptions) - 1 do
      if (length(aOptions[i].ShortOptions) = 0) and (length(aOptions[i].LongOptions) = 0) then
        begin
        result := i;
        exit;
        end;
    end; // NonOptionIndex
  // Identified an option as a non-option, being processed
  procedure ProcessANonOption;
    var OptionIndex : integer;
    begin
    OptionIndex := NonOptionIndex;
    if OptionIndex >= 0 then
      AddResult(false, aOptions[OptionIndex].ReturnValue, OptionIndex, true, ParamProcessed, ParamProcessed)
    else
      AddResult(false, '', OptionIndex, false, ParamProcessed, ParamProcessed);
    ParamProcessed := ''; // finished, can use the next one
    end; // ProcessANonOption
  // Process one or more options in one command line parameter, can be short, long or non-option
  procedure ProcessOneParameter;
    begin
    // Process the value of ParamProcessed
    while length(ParamProcessed) > 0 do
      begin
      case OptionMode of
        omShortOption:
          ProcessAShortOption;
        omLongOption:
          ProcessALongOption;
        omNonOption, omNonOptions:
          ProcessANonOption;
        end; // case
      end; // while
    end; // ProcessOneParameter
  // Sort the results as requested
  procedure CreateTheFinalResult;
    var
      RealOptionCount : integer;
      NonOptionCount : integer;
      i : integer;
    begin
    case aSorting of
      soDefinition:
        begin // sort the Result as per the sequence of definitions
        AnySort(Result[0], length(Result), sizeof(tOptionResult), @CompareDefinitionIndex);
        exit;
        end;
      soReturnValue:
        begin // sort the Result as per the return values
        AnySort(Result[0], length(Result), sizeof(tOptionResult), @CompareReturnValue);
        exit;
        end;
      soInput:
        begin // no need to do anything
        exit;
        end; // soInput
      else // soClassic or any other wrong value
        begin // append the options and non-options
        NonOptionCount := length(NonOptions);
        if NonOptionCount > 0 then
          begin
          RealOptionCount := length(Result);
          SetLength(Result,RealOptionCount + NonOptionCount);
          for i:= 0 to NonOptionCount -1 do
            Result[RealOptionCount + i] := NonOptions[i];
          SetLength(NonOptions,0);
          end;
        exit;
        end; // soClassic
      end; // case
    end; // CreateTheFinalResult
  // The main body of the function
  begin
  Result := nil;
  SetLength(Result,0);
  while ParamIndex <= ParamCount do
    begin
    // Take one comand line parameter
    ParamProcessed := ParamStr(ParamIndex);
    // Decide what option mode is found
    DecideOptionMode;
    // Process the value of ParamProcessed
    ProcessOneParameter;
    // Take the next one (ProcessOneParameter might have skipped one)
    inc(ParamIndex);
    end; // while
  // Create the final result
  CreateTheFinalResult;
  end; // CommandLineParameters

end. // unit

