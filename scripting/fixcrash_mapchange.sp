#include <sourcemod> 
#pragma newdecls required

public Plugin myinfo =
{
	name = "Fix Mapchange Crash",
	author = "Ilusion9",
	description = "Fix clients crash on map change.",
	version = "1.1",
	url = "https://github.com/Ilusion9/"
};

bool g_BlockMapChange;
bool g_ReconnectingClients;

public void OnPluginStart() 
{ 
	AddCommandListener(CommandListener_ChangeLevel, "map");
	AddCommandListener(CommandListener_ChangeLevel, "changelevel");
}

public void OnMapStart()
{
	g_BlockMapChange = false;
	g_ReconnectingClients = false;
}

public Action CommandListener_ChangeLevel(int client, const char[] command, int args)
{
	if (client)
	{
		return Plugin_Continue;
	}
	
	// block map changes while reconnecting all clients
	if (g_ReconnectingClients)
	{
		return Plugin_Handled;
	}
	
	// allow map changes after reconnecting all clients
	if (g_BlockMapChange)
	{
		g_BlockMapChange = false;
		return Plugin_Continue;
	}
	
	g_BlockMapChange = true;
	g_ReconnectingClients = true;
	
	// reconnect all clients
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{                 
			ClientCommand(i, "disconnect;retry"); 
		} 
	}
	
	// delay the map change
	char buffer[PLATFORM_MAX_PATH];
	GetCmdArgString(buffer, sizeof(buffer));
	Format(buffer, sizeof(buffer), "%s %s", command, buffer);
	
	DataPack pk = new DataPack();
	pk.WriteString(buffer);
	
	CreateTimer(0.2, Timer_ForceMapChange, pk, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

public Action Timer_ForceMapChange(Handle timer, DataPack pk)
{
	pk.Reset();
	char buffer[PLATFORM_MAX_PATH];
	pk.ReadString(buffer, sizeof(buffer));
	delete pk;
	
	g_ReconnectingClients = false;
	ServerCommand(buffer);
}
