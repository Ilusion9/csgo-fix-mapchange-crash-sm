#pragma newdecls required
#include <sourcemod> 

public Plugin myinfo =
{
	name = "Fix Mapchange Crash",
	author = "Ilusion9",
	description = "Fix players crash on map change.",
	version = "1.2",
	url = "https://github.com/Ilusion9/"
};

#define MAP_RECONNECTING_CLIENTS                (1 << 0)
#define MAP_ALLOW_NORMAL_CHANGE                 (1 << 1)

int g_MapFlags;

public void OnPluginStart() 
{ 
	AddCommandListener(CommandListener_ChangeLevel, "map");
	AddCommandListener(CommandListener_ChangeLevel, "changelevel");
}

public void OnMapStart()
{
	g_MapFlags = 0;
}

public Action CommandListener_ChangeLevel(int client, const char[] command, int args)
{
	if (client)
	{
		return Plugin_Continue;
	}
	
	if (view_as<bool>(g_MapFlags & MAP_RECONNECTING_CLIENTS))
	{
		return Plugin_Handled;
	}
	
	if (view_as<bool>(g_MapFlags & MAP_ALLOW_NORMAL_CHANGE))
	{
		g_MapFlags &= ~MAP_ALLOW_NORMAL_CHANGE;
		return Plugin_Continue;
	}
	
	g_MapFlags |= MAP_ALLOW_NORMAL_CHANGE;
	g_MapFlags |= MAP_RECONNECTING_CLIENTS;
	
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{                 
			ClientCommand(i, "disconnect;retry"); 
		} 
	}
	
	char arguments[PLATFORM_MAX_PATH];
	GetCmdArgString(arguments, sizeof(arguments));
	Format(arguments, sizeof(arguments), "%s %s", command, arguments);
	
	DataPack pk;
	CreateDataTimer(0.2, Timer_ForceMapChange, pk, TIMER_FLAG_NO_MAPCHANGE);
	pk.WriteString(arguments);
	
	return Plugin_Handled;
}

public Action Timer_ForceMapChange(Handle timer, DataPack pk)
{
	pk.Reset();
	char arguments[PLATFORM_MAX_PATH];
	pk.ReadString(arguments, sizeof(arguments));
	
	g_MapFlags &= ~MAP_RECONNECTING_CLIENTS;
	ServerCommand(arguments);
}
