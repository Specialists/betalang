module core.kernel;

import parser.types;

version = EnumerateMembers;

private shared Class[string] classDeclarations;
private shared Variable[string] variableDeclarations;
private shared Task[string] taskDeclarations;

private Class[string] staticClasses;
private Variable[string] globalVariables;
private Task[string] globalTasks;

class BetaCoreException : Throwable { this(string msg) { super(msg); } }

private shared bool running;
private shared bool error;

private shared string[][] exceptions;

void throwException(string exceptionType, string exception) {
	synchronized {
		auto exc = cast(string[][])exceptions;
		exc ~= [exceptionType, exception];
		exceptions = cast(shared(string[][]))exc;
		
		running = cast(shared(bool))false;
		error = cast(shared(bool))true;
	}
	
	throw new BetaCoreException("kernel.d -> void throwException(string,string);");
}

string[][] getExceptions() {
	synchronized {
		return cast(string[][])exceptions;
	}
}

@property {
	bool isRunning() { return running; }
	bool hasError() { return error; }
}

void initThread() {
	synchronized {
		auto classes = cast(Class[string])classDeclarations;
		
		foreach (newClass; classes.values) {
			auto nClass = newClass.copy();
			nClass.name = newClass.name;
			staticClasses[nClass.name] = nClass;
		}
		
		auto variables = cast(Variable[string])variableDeclarations;
		
		foreach (newVar; variables.values) {
			auto nVar = newVar.copy();
			nVar.name = newVar.name;
			globalVariables[nVar.name] = nVar;
		}
		
		auto tasks = cast(Task[string])taskDeclarations;
		
		foreach (newTask; tasks.values) {
			auto nTask = newTask.copy();
			nTask.name = newTask.name;
			globalTasks[nTask.name] = nTask;
		}
	}
}

void initClass(Class newClass) {
	synchronized {
		auto classes = cast(Class[string])classDeclarations;
		classes[newClass.name] = newClass;
		classDeclarations = cast(shared(Class[string]))classes;
	}
}

Class getNewClass(string className) {
	if (!classExists(className)) {
		throwException("CoreException", "Invalid class instance.");
	}
	
	synchronized {
		auto classes = cast(Class[string])classDeclarations;
		auto newClass = classes[className].copy();
		return newClass;
	}
}

bool classExists(string className) {
	synchronized {
		auto classes = cast(Class[string])classDeclarations;
		return !(classes.get(className, null) is null);
	}
}

Class getStaticClass(string className) {
	return staticClasses[className];
}

void initVar(Variable newVar) {
	synchronized {
		auto variables = cast(Variable[string])variableDeclarations;
		variables[newVar.name] = newVar;
		variableDeclarations = cast(shared(Variable[string]))variables;
	}
}

Variable getNewVar(string varName) {
	if (!varExists(varName)) {
		throwException("CoreException", "Invalid variable instance.");
	}
	
	synchronized {
		auto variables = cast(Variable[string])variableDeclarations;
		auto newVar = variables[varName].copy();
		return newVar;
	}
}

bool varExists(string varName) {
	synchronized {
		auto variables = cast(Variable[string])variableDeclarations;
		return !(variables.get(varName, null) is null);
	}
}

Variable getGlobalVar(string varName) {
	return globalVariables[varName];
}

void initTask(Task newTask) {
	synchronized {
		auto tasks = cast(Task[string])taskDeclarations;
		tasks[newTask.name] = newTask;
		taskDeclarations = cast(shared(Task[string]))tasks;
	}
}

Task getNewTask(string taskName) {
	if (!taskExists(taskName)) {
		throwException("CoreException", "Invalid task instance.");
	}
	
	synchronized {
		auto tasks = cast(Task[string])taskDeclarations;
		auto newTask = tasks[taskName].copy();
		return newTask;
	}
}

bool taskExists(string taskName) {
	synchronized {
		auto tasks = cast(Task[string])taskDeclarations;
		return !(tasks.get(taskName, null) is null);
	}
}

Task getGlobalTask(string taskName) {
	return globalTasks[taskName];
}

void execute(string[] args) {
	if (!taskExists("main")) {
		throwException("NoEntryPointException", "task main() was not found.");
	}
	else {
		auto mainTask = getGlobalTask("main");
		mainTask.execute(null, false);
	}
}

version (EnumerateMembers) {
import std.stdio : writeln;

private string displayTab(int n) {
	string res;
	for (int i = 0; i < n; i++) {
	    res ~= "\t";
	}
	return res;
}

void displayMembers() {
	writeln("Classes:");
	auto classes = cast(Class[string])classDeclarations;
	foreach (c; classes.values) {
		try { displayClass(c, 1); } catch { }
		writeln();
	}
    writeln("Global Variables:");
	foreach (gVar; globalVariables.values) {
		displayVariable(gVar, 1);
		writeln();
	}
	
	writeln("Global Tasks:");
	foreach (gTask; globalTasks.values) {
		displayTask(gTask, 1);
		writeln();
	}
}

void displayClass(Class _class, int tab) {
	writeln(displayTab(tab), "Name: ", _class.name);
	foreach (base; _class.bases.values) {
		writeln(displayTab(tab), "Base: ", base.name);
	}
	tab++;
	foreach (var; _class.variables.values) {
		displayVariable(var, tab);
		writeln();
	}
	tab--;
}

void displayTask(Task task, int tab) {
	writeln(displayTab(tab), "Name: ", task.name);
	writeln(displayTab(tab), "Return Type: ", task.returnType);
	tab++;
	foreach (param; task.parameters) {
		displayVariable(param, tab);
	}
	tab--;
}

void displayVariable(Variable var, int tab) {
	writeln(displayTab(tab), "Name: ", var.name);
	if (var.type == VariableType.Class)
		writeln(displayTab(tab), "Class: ", (cast(Class)var).typeName);
	writeln(displayTab(tab), "Type: ", var.type);
	writeln(displayTab(tab), "Mutable: ", var.mutable);
	if (var.refType)
		writeln(displayTab(tab), "RefType: ", var.refType);
	if (var.type != VariableType.Class && var.type != VariableType.Array) {
		if (!var.isNull)
			writeln(displayTab(tab), "Value: '", var.toString, "'");
	}
} }