module parser.types;

import std.conv;

import core.kernel;
import core.execute;

// version = MixinTest_typeif;
// version = VariableTest;

private string COMPILE_getValues() {
	import std.string;
	
	string[] types =
	[
		"byte", "short","int","long",
		"ubyte","ushort","uint","ulong",
		"float","double","real"
	];
	string mixinTemplateString = "%s get_%s() { return *cast(%s*)&buffer; }\r\n";
	string mixinString;
						
	foreach (type; types) {
		mixinString ~= format(mixinTemplateString, type, type, type);
	}
	
	return mixinString;
}

version (MixinTest_typeif) {
unittest {
	import std.stdio;
	write(COMPILE_typeif);
} }

enum VariableType : string {
	Void = "void",
	Type = "type",
	Int8 = "byte", Int16 = "short", Int32 = "int", Int64 = "long",
	UInt8 = "ubyte", UInt16 = "ushort", UInt32 = "uint", UInt64 = "ulong",
	Float = "float", Double = "double", Real = "real",
	String = "string", Char = "char",
	Bool = "bool",
	Array = "array",
	Class = "class", Struct = "struct",
	Task = "task"
}

private byte[string] sizeByType;

static this() {
	sizeByType["void"] = 0;
	sizeByType["type"] = 0;
	sizeByType["byte"] = 1;
	sizeByType["short"] = 2;
	sizeByType["int"] = 4;
	sizeByType["long"] = 8;
	sizeByType["ubyte"] = 1;
	sizeByType["ushort"] = 2;
	sizeByType["uint"] = 4;
	sizeByType["ulong"] = 8;
	sizeByType["float"] = 4;
	sizeByType["double"] = 8;
	sizeByType["real"] = 16;
	sizeByType["char"] = 1;
	sizeByType["string"] = 0;
	sizeByType["bool"] = 1;
	sizeByType["array"] = 0;
	sizeByType["class"] = 0;
	sizeByType["struct"] = 0;
	sizeByType["task"] = 0;
}

enum RefType : byte {
	None,
	Ref,
	Out
}

class Variable {
private:
	ubyte[] buffer;
	VariableType m_type;
public:
	string name;
	bool mutable = true;
	RefType refType = RefType.None;
	byte byteSize;
	
	this(VariableType type) {
		m_type = type;
		if (m_type == VariableType.String || m_type == VariableType.Array || m_type == VariableType.Class || m_type == VariableType.Struct)
			return;
		
		byteSize = sizeByType[cast(string)m_type];
	}
	
	mixin(COMPILE_getValues);
	string get_string() { return cast(string)buffer; }
	char get_char() { return cast(char)buffer[0]; }
	bool get_bool() { return buffer[0] > 0; }
	
	void setValue(T)(T value) {
		import std.c.string;
		
		buffer = new ubyte[byteSize];
		memcpy(&buffer, &value, (value.sizeof > buffer.length ? buffer.length : value.sizeof));
	}
	
	void setStringValue(string value) {
		buffer = cast(ubyte[])value;
	}
	
	void setCharValue(char value) {
		buffer = [cast(ubyte)value];
	}
	
	void setBoolValue(bool value) {
		buffer = [(value ? 1 : 0)];
	}
	
	void appendString(string value) {
		buffer ~= value;
	}
	
	void appendChar(char value) {
		buffer ~= to!string(value);
	}
	
	@property {
		VariableType type() { return m_type; }
	}
	
	bool isNull() {
		if (!buffer)
			return true;
		if (buffer.length == 0)
			return true;
			
		return false;
	}
	
	ubyte[] toBuffer() {
		if (buffer)
			return buffer;
		else
			return null;
	}
			
	Variable copy()
	{
		auto newVar = new Variable(m_type);
		if (buffer)
			if (buffer.length > 0)
				newVar.buffer = buffer;
		newVar.mutable = mutable;
		if (refType)
			newVar.refType = refType;
		return newVar;
	}
	
	override string toString() {
		switch (type) {
			case VariableType.String:
				return get_string;
			case VariableType.Char:
				return to!string(get_char);
			case VariableType.Bool:
				return to!string(get_bool);
			case VariableType.Int8:
				return to!string(get_byte);
			case VariableType.Int16:
				return to!string(get_short);
			case VariableType.Int32:
				return to!string(get_int);
			case VariableType.Int64:
				return to!string(get_long);
			case VariableType.UInt8:
				return to!string(get_ubyte);
			case VariableType.UInt16:
				return to!string(get_ushort);
			case VariableType.UInt32:
				return to!string(get_uint);
			case VariableType.UInt64:
				return to!string(get_ulong);
			case VariableType.Float:
				return to!string(get_float);
			case VariableType.Double:
				return to!string(get_double);
			case VariableType.Real:
				return to!string(get_real);
			default: {
				throwException("NullReferenceException", name ~ " is null.");
				break;
			}
		}
		return null;
	}
	
	void fromString(string s) {
		switch (type) {
			case VariableType.String:
				setStringValue(s);
				break;
			case VariableType.Char:
				setCharValue(s[0]);
				break;
			case VariableType.Bool:
				setBoolValue(to!bool(s));
				break;
			case VariableType.Int8:
				setValue!(byte)(to!byte(s));
				break;
			case VariableType.Int16:
				setValue!(short)(to!short(s));
				break;
			case VariableType.Int32:
				setValue!(int)(to!int(s));
				break;
			case VariableType.Int64:
				setValue!(long)(to!long(s));
				break;
			case VariableType.UInt8:
				setValue!(ubyte)(to!ubyte(s));
				break;
			case VariableType.UInt16:
				setValue!(ushort)(to!ushort(s));
				break;
			case VariableType.UInt32:
				setValue!(uint)(to!uint(s));
				break;
			case VariableType.UInt64:
				setValue!(ulong)(to!ulong(s));
				break;
			case VariableType.Float:
				setValue!(float)(to!float(s));
				break;
			case VariableType.Double:
				setValue!(double)(to!double(s));
				break;
			case VariableType.Real:
				setValue!(real)(to!real(s));
				break;
			default: {
				throwException("InvalidTypeException", name ~ " is not compatible with string.");
				break;
			}
		}
	}
	
	int sizeOf() {
		if (buffer)
			return buffer.length;
		return 0;
	}
}

version (VariableTest) {
unittest {
	import std.stdio;
	
	auto var = new Variable(VariableType.Int32);
	var.setValue!(int)(500);
	int value = var.get_int;
	
	writeln(value);
	
	auto var2 = new Variable(VariableType.String);
	var.setValue("Hello World!");
	string value2 = var.get_string;
	
	writeln(value2);
} }

class Array : Variable {
private:
	Variable[] m_array;
public:
	this() { super(VariableType.Array); }
	this(int size) { m_array = new Variable[size]; this(); }
	this(Array arr) { m_array = arr.m_array; this(); }
	
	override Array copy() {
		auto newArray = new Array;
		if (m_array) {
			newArray.m_array = new Variable[m_array.length];
			foreach (var; m_array)
				newArray.m_array ~= var.copy();
		}
		newArray.mutable = mutable;
		return newArray;
	}
	
	Variable getByIndex(int index) {
		return m_array[index];
	}
	
	void setByIndex(int index, Variable var) {
		m_array[index] = var;
	}
	
	@property {
		int length() {
			if (!m_array)
				return -1;
			return m_array.length;
		}
	}
	
	override bool isNull() {
		return length == -1;
	}
	
	override string toString() {
		if (length == 0)
			return "[]";
		string res = "[";
		foreach (var; m_array) {
			res ~= var.toString ~ ",";
		}
		res.length -= 1;
		res ~= "]";
		return res;
	}
	
	override int sizeOf() {
		int res = 0;
		foreach (var; m_array)
			res += var.sizeOf();
		return res;
	}
}

class Class : Variable {
private:
	bool hasInit = false; // when constructor is called this is set to true ...
public:
	Class[string] bases;
	Variable[string] variables;
	Task[string] tasks;
	string typeName; // class name, not var name ...
	
	Task constructor;
	Task destructor;
	
	this() {
		super(VariableType.Class);
	}
	
	void setBaseData(Class baseClass) {
		foreach (var; baseClass.variables.values) {
			variables[var.name] = var;
		}
		foreach (task; baseClass.tasks.values) {
			tasks[task.name] = task;
		}
	}
	
	override bool isNull() {
		return hasInit;
	}
	
	override Class copy() {
		auto newClass = new Class;
		newClass.typeName = typeName;
		foreach (b; bases.values) {
			auto newBase = b.copy();
			import std.stdio;
			writeln(name, " : ", b.name);
			newBase.name = b.name;
			newClass.bases[newBase.name] = newBase;
		}
		foreach (v; variables.values) {
			newClass.variables[v.name] = v.copy();
		}
		foreach (t; tasks.values) {
			newClass.tasks[t.name] = t.copy();
		}
		newClass.typeName = typeName;
		newClass.mutable = mutable;
		if (newClass.constructor)
			newClass.constructor = constructor.copy();
		if (newClass.destructor)
			newClass.destructor = destructor.copy();
		return newClass;
	}
	
	override int sizeOf() {
		int res = 0;
		foreach (b; bases.values)
			res += b.sizeOf();
		foreach (v; variables.values)
			res += v.sizeOf();
		return res;
	}
}

class Task : Variable {
public:
	Variable[string] variables;
	Variable[] parameters;
	VariableType returnType;
	bool callable = true;
	
	Instruction[] instructions;
	
	this() {
		super(VariableType.Task);
	}
	
	Variable execute(Variable[] params, bool newThread) {
		import core.execute;
		return executeTask(this, returnType, params, newThread);
	}
	
	override Task copy() {
		auto newTask = new Task;	
		foreach (var; variables.values) {
			auto nVar = var.copy();
			nVar.name = var.name;
			newTask.variables[nVar.name] = nVar;
		}
		
		foreach (param; parameters) {
			auto nParam = param.copy();
			nParam.name = param.name;
			newTask.parameters ~= nParam;
			newTask.variables[nParam.name] = nParam;
		}
		
		newTask.returnType = returnType;
		return newTask;
	}
}