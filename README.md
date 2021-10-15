# getoptionsforpascal
Process and get the Command Line options, following the "standard" GNU like input standard, but return the result in one step, unlike the widely used C getopt library and its Pascal equivalent.

To use Command Line options is widely used in different operating systems. Most programs follow the de-facto standard (GNU style) using single char options like -a and long options like --verbose, sometimes with mandatory or optional arguments, like --filename=myfile.dat. It is highly recommended for any new development to follow the same conventions.

C has a standard library available in most systems, 'getopt'. There is a Pascal version of the same, strictly following the C logic: https://www.freepascal.org/docs-html/rtl/getopts/index.html. There are various issues with this one that are done differently in the new GetOptions unit:

- There is a separate handling of short (historically only available) options and the later added long options. For short options a special string has to be composed, while for the long options an array is used.
- Options and so-called Non-option parameters are returned one-by-one in an old fashioned loop. In this current unit, the result is given back in one step. Obviously, it might need a loop to read the result if the options are to be processed one-by-one, but there are two important differences: (1) The result of the processing of the Command Line options is stored in an array and can be used later without calling the GetOpt again. (2) If only Flags are used (i.e. variables set by the options, but no arguments) there is no need of a loop at all.
- In the design of GetOpt a long option can give back a short option value (this is logic and needed obviously), but the underlying specification of the long option and the short option can be different. As a result --filename (with no or with not-given optional argument) can return the same 'f' as the short option -f that has a mandatory argument. The new unit has a specification structure connecting the short and long options more closely.
- The return value of GetOpt (and its long version) is a Char, limiting the use of the result. The new unit can return any string.
- In the design of GetOpt missing argument errors in a long name option are not identified: https://forum.lazarus.freepascal.org/index.php/topic,56693.0.html. This is different in this unit.
- There are two more potential bugs in the implementation: https://forum.lazarus.freepascal.org/index.php/topic,56701.0.html and https://forum.lazarus.freepascal.org/index.php/topic,56702.0.html. The current proposed unit is - hoped to be - free from such bugs.

For all more details, please read the cmdlinedemo.pas header and check how it works. Also, please read the heading and the record specification in the interface section of the getoptions.pas unit.
