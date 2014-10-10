module core.utils;

import std.array;
import std.algorithm;

string getPathName(string path) {
	auto pathSplit = split(path, "\\");
	if (canFind(pathSplit[pathSplit.length - 1], ".")) {
		auto fName = pathSplit[pathSplit.length - 1];
		auto nPath = path[0 .. (path.length - (fName.length)) - 1];
		return stripRight(nPath, '\\');
	}
	else {
		if (endsWith(path, "\\"))
			return stripRight(path, '\\');
		return path;
	}
}

string makeValidString(string s) {
	ubyte[] buffer = cast(ubyte[])s;
	ubyte[] nbuff;
	foreach (b; buffer) {
		if (b != 0 && b != 13) {
			nbuff ~= b;
		}
	}
	return cast(string)nbuff;
}

bool isNumeric(string s, bool floatPoint) {
	foreach (c; s) {
		if (c < 48 || c > 57) {
			if (!floatPoint || floatPoint && c != 46) {
				return false;
			}
		}
	}
	
	return true;
}