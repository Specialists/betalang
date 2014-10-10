module core.settings;

import std.conv;

alias map = string[string];

private shared map m_settings;

auto getSetting(T)(string name) {
	synchronized {
		auto settings = cast(map)m_settings;
		auto val = settings.get(name, null);
		return to!T(val);
	}
}

void setSetting(T)(string name, T value) {
	synchronized {
		auto settings = cast(map)m_settings;
		settings[name] = to!string(value);
		m_settings = cast(shared(map))settings;
	}
}