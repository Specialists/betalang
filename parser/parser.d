module parser.parser;

import std.array;
import std.algorithm;
import std.string;
import std.conv;

import parser.tokenizer;
import parser.types;

import core.settings;
import core.utils;
import core.kernel;
import core.execute;

private string[] errorReports;
void reportError(string error, string file, int line, string code) {
	import std.file : exists;
	if (exists(getSetting!(string)("MainFilePath") ~ file))
		errorReports ~= "<std-lib>(" ~ file ~ ")[" ~ to!string(line + 1) ~ "]" ~ error;
	if (exists(getSetting!(string)("CompilerPath") ~ "\\lib\\" ~ file))
		errorReports ~= "<std-lib>(" ~ file ~ ")[" ~ to!string(line + 1) ~ "]" ~ error;
	else
		errorReports ~= "(" ~ file ~ ")[" ~ to!string(line + 1) ~ "]" ~ error;
}

string[] getErrors() {
	return errorReports;
}

class CodeParser {
private:
	string[] lines;
	int currentLine;
	string fileName;
	string[string] aliases;
public:
	this(string fileName) {
		this.fileName = fileName;
		currentLine = 0;
	}
	
	void parse(string parentFile, int parentLine, string parentCode) {	
		import std.file;
		
		if (canFind(fileName, "\\") && !canFind(fileName, "C:\\")) {
			reportError(
			"Invalid module specification.",
			parentFile,
			parentLine,
			parentCode);
			return;
		}
		if (!endsWith(fileName, ".beta")) {
			fileName = replace(fileName, ".", "\\");
			fileName ~= ".beta";
		}
		
		string readFile = fileName;
		
		auto mnFile = getSetting!(string)("MainFilePath") ~ "\\" ~ fileName;
		if (!exists(mnFile)) {
			auto cmpFile = getSetting!(string)("CompilerPath") ~ "\\lib\\" ~ fileName;
			
			if (!exists(cmpFile)) {
				if (!exists(fileName)) {
					reportError(
					"Cannot read module " ~ fileName,
					parentFile,
					parentLine,
					parentCode);
					return;
				}
			}
			else
				readFile = getSetting!(string)("CompilerPath") ~ "\\lib\\" ~ fileName;
		}
		else
			readFile = getSetting!(string)("MainFilePath") ~ "\\" ~ fileName;

		string text = readText(readFile);
		text = makeValidString(text);
		lines = split(text, "\n");
		
		for (int i = 0; i < lines.length; i++)
		{
			string line = lines[i];
			
			if (!line || line == "" || line.length <= 1) {
				currentLine++;
				continue;
			}
			
			line = stripLeft(line, ' ');
			line = stripLeft(line, '\t');
			line = stripRight(line, ' ');
			line = stripRight(line, '\t');
			
			if (!line || line == "" || line.length <= 1) {
				currentLine++;
				continue;
			}
			
			foreach (a; aliases.keys)
				line = replace(line, a, aliases[a]);
			
			auto lineSplit = split(line, " ");
			
			switch (lineSplit[0])
			{
				case "alias": {
					string aliasName = lineSplit[1];
					string aliasValue = line[lineSplit[0].length + lineSplit[1].length + 2 .. $];
					aliases[aliasName] = aliasValue;
					break;
				}
				
				case "import": {
					if (lineSplit.length != 2) {
						reportError(
						"Invalid arguments for module import. Use: import MODULE_PATH",
						fileName,
						currentLine,
						line);
						
						currentLine++;
						continue;
					}
					
					auto nCodeParser = new CodeParser(lineSplit[1]);
					nCodeParser.parse(fileName, currentLine, line);
					break;
				}
				
				case "class": {
					auto tokenizer = new ClassTokenizer;
					string err = tokenizer.tokenize(line);
					if (err) {
						reportError(err, fileName, currentLine, line);
					}
					else {
						auto newClass = new Class;
						newClass.name = tokenizer.name;
						newClass.typeName = tokenizer.name;
						foreach (base; tokenizer.baseNames) {
							if (classExists(base)) {
								auto baseClass = getNewClass(base);
								baseClass.name = base;
								newClass.bases[base] = baseClass;
								newClass.setBaseData(baseClass);
							}
						}
						initClass(newClass);
						
						currentLine++;
						if (parseClass(newClass)) {
							i = currentLine;
							continue;
						}
						else {
						reportError(
							newClass.name ~ " has no ending statement",
							fileName,
							currentLine,
							"");
						}
					}
					break;
				}
				
				// task & variable ...
				default: {
					if (!lineSplit[0] || lineSplit[0] == "") {
						currentLine++;
						continue;
					}
					
					if (startsWith(lineSplit[0], "task")) {
						auto tokenizer = new TaskTokenizer;
						string err = tokenizer.tokenize(line);
						if (err) {
							reportError(err, fileName, currentLine, line);
						}
						else {
							auto task = new Task;
							task.name = tokenizer.name;
							task.returnType = cast(VariableType)tokenizer.returnType;
							foreach (param; tokenizer.parameters) {
								auto var = new Variable(cast(VariableType)param.type);
								var.name = param.name;
								if (param.refOut)
									var.refType = (param.refOut == "ref" ? RefType.Ref : RefType.Out);
								var.mutable = param.mutability != "immutable";
								task.parameters ~= var;
								task.variables[var.name] = var;
							}
							initTask(task);
						}
					}
					else {
						if (validType(lineSplit[0]) ||
							classExists(lineSplit[0])) {
								auto tokenizer = new VariableTokenizer;
								auto err = tokenizer.tokenize(line);
								if (err) {
									reportError(
									err,
									fileName,
									currentLine,
									line);
								}
								else { // check array, class ...
									if (classExists(lineSplit[0])) {
										auto var = getNewClass(lineSplit[0]);
										var.name = tokenizer.name;
										var.mutable = tokenizer.mutability != "immutable";
										initVar(var);
									}
									else if (lineSplit[0] == "array") {
										auto var = new Array(to!int(tokenizer.value));
										var.name = tokenizer.name;
										var.mutable = tokenizer.mutability != "immutable";
										initVar(var);
									}
									else {
										auto var = new Variable(cast(VariableType)tokenizer.type);
										var.name = tokenizer.name;
										if (tokenizer.mutability)
											var.mutable = tokenizer.mutability != "immutable";
										if (tokenizer.value)
											var.fromString(tokenizer.value);
											
										initVar(var);
									}
								}
						}
						else {
							reportError(
							"Invalid parsing argument for global declarations.",
							fileName,
							currentLine,
							line);
						}
					}
					
					break;
				}
			}
			
			currentLine++;
		}
	}
	
private:
	bool parseClass(Class newClass) {
		const string endState = ")";
		for (int i = currentLine; i < lines.length; i++)
		{
			string line = lines[i];
			if (line == endState) {
				currentLine++;
				return true;
			}
			
			if (!line || line == "" || line.length <= 1) {
				currentLine++;
				continue;
			}
			
			line = stripLeft(line, ' ');
			line = stripLeft(line, '\t');
			line = stripRight(line, ' ');
			line = stripRight(line, '\t');
			
			if (line == endState) {
				currentLine++;
				return true;
			}
			
			if (!line || line == "" || line.length <= 1) {
				currentLine++;
				continue;
			}
			
			foreach (a; aliases.keys)
				line = replace(line, a, aliases[a]);
			
			auto lineSplit = split(line, " ");
			
			switch (lineSplit[0])
			{
				// New keywords ...
				
				// task & variable ...
				default: {
					if (!lineSplit[0] || lineSplit[0] == "") {
						currentLine++;
						continue;
					}
					
					if (startsWith(lineSplit[0], "task")) {
						auto tokenizer = new TaskTokenizer;
						string err = tokenizer.tokenize(line);
						if (err) {
							reportError(err, fileName, currentLine, line);
						}
						else {
							auto task = new Task;
							task.name = tokenizer.name;
							if (task.name == "this") {
								task.callable = false;
								newClass.constructor = task;
							}
							else if (task.name == "~this") {
								task.callable = false;
								newClass.destructor = task;
							}
							task.returnType = cast(VariableType)tokenizer.returnType;
							foreach (param; tokenizer.parameters) {
								auto var = new Variable(cast(VariableType)param.type);
								var.name = param.name;
								if (param.refOut)
									var.refType = (param.refOut == "ref" ? RefType.Ref : RefType.Out);
								var.mutable = param.mutability != "immutable";
								task.parameters ~= var;
								task.variables[var.name] = var;
							}
							if (task.callable)
								newClass.tasks[task.name] = task;
						}
					}
					else {
						if (validType(lineSplit[0]) ||
							classExists(lineSplit[0])) {
								auto tokenizer = new VariableTokenizer;
								auto err = tokenizer.tokenize(line);
								if (err) {
									reportError(
									err,
									fileName,
									currentLine,
									line);
								}
								else { // check array, class ...
									if (classExists(lineSplit[0])) {
										auto var = getNewClass(lineSplit[0]);
										var.name = tokenizer.name;
										var.mutable = tokenizer.mutability != "immutable";
										newClass.variables[var.name] = var;
									}
									else if (lineSplit[0] == "array") {
										auto var = new Array(to!int(tokenizer.value));
										var.name = tokenizer.name;
										var.mutable = tokenizer.mutability != "immutable";
										newClass.variables[var.name] = var;
									}
									else {
										auto var = new Variable(cast(VariableType)tokenizer.type);
										var.name = tokenizer.name;
										if (tokenizer.mutability)
											var.mutable = tokenizer.mutability != "immutable";
										if (tokenizer.value)
											var.fromString(tokenizer.value);
											
										newClass.variables[var.name] = var;
									}
								}
						}
						else {
							reportError(
							"Invalid parsing argument for class declarations.",
							fileName,
							currentLine,
							line);
						}
					}
					
					break;
				}
			}
			
			currentLine++;
		}
		return false;
	}
	
	void parseTask() {
	}
}