module core.execute;

import parser.types;
import core.kernel;

enum InstructionType {
	Unknown,
	Call,
	CallReturn,
	Return,
	Jmp,
	If
}

class Instruction {
public:
	InstructionType type;
	this(InstructionType type) {
		this.type = type;
	}
}

class Call : Instruction {
public:
	this() { super(InstructionType.Call); }
	
	Task[string] taskCollection;
	string taskName;

	Variable[string] paramCollection;
	string[] parameters;
	
	Task getTask() { return taskCollection[taskName]; }
}

class CallReturn : Instruction {
public:
	this() { super(InstructionType.CallReturn); }
	
	Task[string] taskCollection;
	string taskName;
	
	Variable[string] paramCollection;
	string[] parameters;
	
	Task getTask() { return taskCollection[taskName]; }
}

Variable executeTask(Task task, VariableType returnType, Variable[] params, bool newThread) {
	if (newThread) {
		import core.thread;
		new Thread({ initThread(); executeTask(task, returnType, params, false); }).start();
	}
	else {
		for (int i = 0; i < task.instructions.length; i++) {
			auto instruction = task.instructions[i];
			
			switch (instruction.type) {
				case InstructionType.Call: {
					auto call = cast(Call)instruction;
					
					auto callTask = call.getTask();
					if (call.parameters) {
						Variable[] callParams;
						foreach (param; call.parameters)
							callParams ~= call.paramCollection[param];
						callTask.execute(callParams, false);
					}
					else
						callTask.execute(null, false);
					break;
				}
				default: break;
			}
		}
	}
	return null;
}