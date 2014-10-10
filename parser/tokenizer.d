module parser.tokenizer;

import std.array;
import std.algorithm;
import std.string;

import core.kernel;

// Unit Test Versions ...
// version = ClassTokenizer;
// version = StructTokenizer;
// version = TaskTokenizer;
// version = VariableTokenizer;

class ClassTokenizer {
private:
	string m_name;
	string[] m_baseNames;
	string[] m_attributes;
	
public:
	string tokenize(string toTokenize) {	
		toTokenize = stripRight(toTokenize, ' ');
		toTokenize = stripRight(toTokenize, '\t');
		toTokenize = stripLeft(toTokenize, ' ');
		toTokenize = stripLeft(toTokenize, '\t');
		
		if (!startsWith(toTokenize, "class"))
			return "Doesn't start with class";
		
		if (!canFind(toTokenize, "(") || toTokenize.length == 1)
			return "Cannot find (";
		auto dataSplit = split(toTokenize, "(");
		if (count(toTokenize, "(") > 1 || dataSplit.length != 2)
			return "Contains multiple ('s";
		if (dataSplit[1].length < 2 && canFind(dataSplit[1], ":"))
			return "There is no base classes defined, despite it being declared";
		else if (dataSplit.length == 2 && !endsWith(dataSplit[1], ':')) {
			if (!dataSplit[1])
				return "Does not end with : when there is base classes specified";
		}
		
		auto classData = split(replace(dataSplit[0], "class ", ""), " ");
		foreach (s; classData) {
			if (startsWith(s, "@")) {
				if (s == "@")
					return "No attribute identifier";
				m_attributes ~= stripLeft(s, '@');
			}
			else if (m_name)
				return "Multiple class identifiers";
			else
				m_name = s;
		}
		
		if (!m_name)
			return "No class identifier.";
		
		if (dataSplit[1].length > 2) {
			string baseInfo = dataSplit[1];
			baseInfo = strip(baseInfo, ' ');
			baseInfo = baseInfo[0 .. $ - 1];
			baseInfo = replace(baseInfo, " ", "");
			m_baseNames = split(baseInfo, ",");
		}
		
		return null;
	}
	
	@property {
		string name() { return m_name; }
		string[] baseNames() { return m_baseNames; }
		string[] attributes() { return m_attributes; }
	}
}

version(ClassTokenizer) {
unittest {
	// Class Tokenizer Unit Test
	import std.stdio;
	writeln("Beginning Class Tokenizer Unit Test ...");
	
	import std.file;
	
	auto tokenizers = readText("classtokenizer.txt");
	foreach (toTokenize; split(tokenizers, "\r\n")) {
		if (!toTokenize || toTokenize == "")
			continue;
	
		writeln("Tokenizing: ", toTokenize);
	
		auto tokenizer = new ClassTokenizer;
		auto err = tokenizer.tokenize(toTokenize);
		if (err) {
			writeln("Error: ", err);
		}
		else {
			writeln("Class Name: ", tokenizer.name);
			writeln("Attributes:");
			foreach(attr; tokenizer.attributes)
				writeln("\t", attr);
			writeln("Base Classes:");
			foreach(base; tokenizer.baseNames)
				writeln("\t", base);
		}
		writeln(); writeln();
	}
	
	writeln("Finished Class Tokenizer Unit Test ...");
} }

class ParameterData {
public:
	string type; // byte,short,int,long,ubyte,ushort,uint,ulong,float,double,real,char,string,bool,array,class
	string name;
	string refOut; // ref (no-copy passing) out (no-copy passing, new instance required)
	string mutability; // immutable (passed variable cannot be modified)
}

private immutable string[] dataTypes = split("type,byte,short,int,long,ubyte,ushort,uint,ulong,float,double,real,char,string,bool,array,class", ",");

bool validType(string type) {
	return canFind(dataTypes, type);
}

class TaskTokenizer {
private:
	string m_name;
	string m_returnType;
	string[] m_attributes;
	ParameterData[] m_parameters;
public:
	string tokenize(string toTokenize) {	
		toTokenize = stripRight(toTokenize, ' ');
		toTokenize = stripRight(toTokenize, '\t');
		toTokenize = stripLeft(toTokenize, ' ');
		toTokenize = stripLeft(toTokenize, '\t');
		
		if (!startsWith(toTokenize, "task"))
			return "Doesn't start with task";
		
		if (!canFind(toTokenize, "(") || toTokenize.length == 1)
			return "Cannot find (";
		if (count(toTokenize, "(") > 1)
			return "Contains multiple ('s";
			
		auto dataSplit = split(toTokenize, "(");
		
		string taskType = "task";
		if (startsWith(dataSplit[0], "task<")) {
			auto typeData = split(dataSplit[0], " ");
			
			string type = typeData[0];
			if (!endsWith(type, ">"))
				return "Return type does not end with >";
				
			m_returnType = type["task<".length .. $ - 1];
			
			if (!validType(returnType))
				return "Invalid return type";
				
			taskType = type;
		}
		else {
			m_returnType = "void";
		}
			
		if (dataSplit[1].length < 2 && canFind(dataSplit[1], ":"))
			return "There is no parameters defined, despite it being declared";
		else if (dataSplit.length == 2 && !endsWith(dataSplit[1], ':')) {
			if (!dataSplit[1])
				return "Does not end with : when there is parameters specified";
		}
		
		auto classData = split(replace(dataSplit[0], taskType ~ " ", ""), " ");
		foreach (s; classData) {
			if (startsWith(s, "@")) {
				if (s == "@")
					return "No attribute identifier";
				m_attributes ~= stripLeft(s, '@');
			}
			else if (m_name)
				return "Multiple task identifiers";
			else
				m_name = s;
		}
		
		if (!m_name)
			return "No task identifier.";
		
		if (dataSplit[1].length > 2) {
			string baseInfo = dataSplit[1];
			baseInfo = baseInfo[0 .. $ - 1];
			auto params = split(baseInfo, ",");
			foreach (param; params) {
				if (!canFind(param, " "))
					return "Parameter does not contain type or identifier";
				
				auto paramInfo = split(param, " ");
				auto paramData = new ParameterData;
				
				foreach (pData; paramInfo) {
					string data = stripLeft(pData, ' ');
					data = stripRight(data, ' ');
					data = stripLeft(data, '\t');
					data = stripRight(data, '\t');
					
					if (!data || data == "")
						continue;
					
					if (data == "ref" || data == "out")
						paramData.refOut = data;
					else if (data == "immutable")
						paramData.mutability = data;
					else if (validType(data))
						paramData.type = data;
					else if (paramData.name)
						return "Multiple parameter identifier";
					else
						paramData.name = data;
				}
				
				if (!paramData.type)
					return "No parameter type";
				if (!paramData.name)
					return "No parameter identifier";
					
				m_parameters ~= paramData;
			}
		}
		
		return null;
	}
	
	@property {
		string name() { return m_name; }
		string returnType() { return m_returnType; }
		string[] attributes() { return m_attributes; }
		ParameterData[] parameters() { return m_parameters; }
	}
}

version(TaskTokenizer) {
unittest {
	// Task Tokenizer Unit Test
	import std.stdio;
	writeln("Beginning Task Tokenizer Unit Test ...");
	
	import std.file;
	auto tokenizers = readText("tasktokenizer.txt");
	foreach (toTokenize; split(tokenizers, "\r\n")) {
		if (!toTokenize || toTokenize == "")
			continue;
		writeln("Tokenizing: ", toTokenize);
	
		auto tokenizer = new TaskTokenizer;
		auto err = tokenizer.tokenize(toTokenize);
		if (err) {
			writeln("Error: ", err);
		}
		else {
			writeln("Task Name: ", tokenizer.name);
			writeln("Task Return Type: ", tokenizer.returnType);
			writeln("Attributes:");
			foreach(attr; tokenizer.attributes)
				writeln("\t", attr);
			writeln("Parameters:");
			foreach (param; tokenizer.parameters) {
				writeln("\t", param.name);
				writeln("\t", param.type);
				if (param.refOut)
					writeln("\t", param.refOut);
				if (param.mutability)
					writeln("\t", param.mutability);
				writeln();
			}
		}
		writeln(); writeln();
	}
	
	writeln("Finished Task Tokenizer Unit Test ...");
} }

class VariableTokenizer {
private:
	string m_type;
	string m_name;
	string m_mutability;
	string m_value;
public:
	string tokenize(string toTokenize) {
		toTokenize = stripRight(toTokenize, ' ');
		toTokenize = stripRight(toTokenize, '\t');
		toTokenize = stripLeft(toTokenize, ' ');
		toTokenize = stripLeft(toTokenize, '\t');
		
		if (canFind(toTokenize, "=")) {
			if (endsWith(toTokenize, "=")) {
				return "Value of variable not specified";
			}
			
			auto varData = split(toTokenize, "=");
			
			// Identifier Info
			auto vInfo = split(varData[0], " ");
			foreach (vData; vInfo) {
				string data = vData;
				data = stripLeft(data, ' ');
				data = stripLeft(data, '\t');
				
				if (!data || data == "")
					continue;
			
				if (data == "immutable")
					m_mutability = data;
				else if (validType(data))
					m_type = data;
				else if (classExists(data)) {
					m_type = "class";
					m_value = data;
				}
				else if (m_name)
					return "Multiple variable identifier";
				else
					m_name = data;
			}
			
			// Value Info
			if (m_type == "type")
				return "A type cannot have an initialized value.";
			
			string data2 = varData[1];
			data2 = stripLeft(data2, ' ');
			data2 = stripLeft(data2, '\t');
					
			if (m_type == "string") {
				int assign = countUntil(toTokenize, "=");
				int valueIndex = countUntil(toTokenize, "\"") + 1;
				if (assign > valueIndex)
					return "Invalid initialization data";
				if (!endsWith(toTokenize, "\""))
					return "String values must be closed with \"";
				
				m_value = toTokenize[valueIndex .. $ - 1]; // string ...
				
				m_value = replace(m_value, "\\r", "\r");
				m_value = replace(m_value, "\\n", "\n");
				m_value = replace(m_value, "\\t", "\t");
				m_value = replace(m_value, "\\0", "\0");
			}
			else if (m_type == "char" && data2.length == 3 && startsWith(data2, "'") && endsWith(data2, "'")) {
				m_value ~= data2[1]; // char ...
			}
			else if (startsWith(m_type, "class"))
				return "Invalid object data";
			else if (core.utils.isNumeric(data2, (m_type == "float" || m_type == "double" || m_type == "real")))
				m_value = data2;
			else
				return "Invalid initialization data";
		}
		else {
			auto vInfo = split(toTokenize, " ");
			foreach (vData; vInfo) {
				string data = vData;
				data = stripLeft(data, ' ');
				data = stripLeft(data, '\t');
				
				if (!data || data == "")
					continue;
			
				if (data == "immutable")
					m_mutability = data;
				else if (validType(data))
					m_type = data;
				else if (classExists(data)) {
					m_type = "class";
					m_value = data;
				}
				else if (m_name)
					return "Multiple variable identifier";
				else
					m_name = data;
			}
		}
		
		return null;
	}
	
	@property {
		string name() { return m_name; }
		string type() { return m_type; }
		string mutability() { return m_mutability; }
		string value() { return m_value; }
	}
}

version(VariableTokenizer) {
unittest {
	// Variable Tokenizer Unit Test
	import std.stdio;
	writeln("Beginning Variable Tokenizer Unit Test ...");
	
	import std.file;
	auto tokenizers = readText("vartokenizer.txt");
	foreach (toTokenize; split(tokenizers, "\r\n")) {
		if (!toTokenize || toTokenize == "")
			continue;
		writeln("Tokenizing: ", toTokenize);
	
		auto tokenizer = new VariableTokenizer;
		auto err = tokenizer.tokenize(toTokenize);
		if (err) {
			writeln("Error: ", err);
		}
		else {
			writeln("Variable Name: ", tokenizer.name);
			writeln("Variable Type: ", tokenizer.type);
			writeln("Variable Mutability: ", tokenizer.mutability);
			writeln("Variable Value: ", tokenizer.value);
		}
		writeln(); writeln();
	}
	
	writeln("Finished Variable Tokenizer Unit Test ...");
} }