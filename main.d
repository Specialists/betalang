import std.stdio;
import core.kernel;

version = NoTesting;
version = EnumerateMembers;

void main(string[] args) {
	version (NoTesting) {
	try {
		import parser.parser;
		
		if (args.length != 2) {
			writeln("Invalid command line arguments.");
		}
		else {
			import core.utils;
			import core.settings;
			
			string mainFile = args[1];
			auto mainFilePath = getPathName(mainFile);
			auto compilerPath = getPathName(args[0]);
			
			setSetting!(string)("MainFilePath", mainFilePath);
			setSetting!(string)("CompilerPath", compilerPath);
			
			import std.array;
			mainFile = replace(mainFile, mainFilePath ~ "\\", "");
			auto codeParser = new CodeParser(mainFile);
			codeParser.parse(mainFile, 0, "import " ~ mainFile);
		
			auto errors = getErrors();
			if (errors) {
				foreach (err; errors) {
					writeln(err);
				}
			}
			else {
				initThread();
				
				version (EnumerateMembers) { synchronized { displayMembers(); } }
				else { execute(args); }
			}
		}
	}
	catch (Throwable e) {
		writeln(e);
	} }
	readln();
}