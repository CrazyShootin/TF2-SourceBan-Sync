/** Hi my name is Crazy, this plugin handles Bans/Mutes/Gags issued from your SourceBan Panel
 * once they are applied if the user is in-game they will be prompted a message that they have been Banned/Muted/Gagged then they will be promptly kicked 
 * But it also notifies everyone in the Server who/why they have been Banned/Muted/Gagged
 * All prompts can be edited to as you wish 
 **/
#include <sourcemod>
#include <sourcebans>

public Plugin myinfo = 
{
    name = "SourceBan Syncing",
    author = "Crazy",
    description = "Handles Bans, Mutes, and Gags issued from the SourceBan Panel by kicking players and providing reasons for why they have been Banned/Muted/Gagged.",
    version = "1.0",
    url = ""
};

public void OnPluginStart()
{
    // Hook SourceBans Ban, Mute and Gag commands
    AddCommandListener(OnSourceBanAction, "sm_ban");
    AddCommandListener(OnSourceBanAction, "sm_mute");
    AddCommandListener(OnSourceBanAction, "sm_gag");
}

// General handler for SourceBans commands
public Action OnSourceBanAction(int client, const char[] command, int argc)
{
    if (argc >= 3)
    {
        int targetClient = FindTargetClient(argc, 1);
        if (targetClient > 0 && IsClientConnected(targetClient))
        {
            char reason[256];
            GetCmdArgString(reason, sizeof(reason));

            char clientName[MAX_NAME_LENGTH];
            GetClientName(targetClient, clientName, sizeof(clientName));

            if (StrEqual(command, "sm_ban"))
            {
                PrintToChatAll("[AutoMessage] Player %s Has Been Banned.", clientName);
                NotifyAndKickClient(targetClient, reason, "You have been Banned. Reason: %s");
            }
            else if (StrEqual(command, "sm_mute"))
            {
                PrintToChatAll("[AutoMessage] Player %s Has Been Muted.", clientName);
                NotifyAndKickClient(targetClient, reason, "You have been Muted. Reason: %s");
            }
            else if (StrEqual(command, "sm_gag"))
            {
                PrintToChatAll("[AutoMessage] Player %s Has Been Gagged.", clientName);
                NotifyAndKickClient(targetClient, reason, "You have been Gagged. Reason: %s");
            }
        }
    }
    return Plugin_Continue;
}

int FindTargetClient(int argc, int argIndex)
{
    if (argc > argIndex)
    {
        char targetName[64];
        GetCmdArg(argIndex, targetName, sizeof(targetName));
        return GetClientFromName(targetName);
    }
    return -1;
}

int GetClientFromName(const char[] name)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i))
        {
            char clientName[MAX_NAME_LENGTH];
            GetClientName(i, clientName, sizeof(clientName));
            if (StrEqual(clientName, name, false))
            {
                return i;
            }
        }
    }
    return -1;
}

void NotifyAndKickClient(int clientIndex, const char[] reason, const char[] messageFormat)
{
    new String:message[256];
    Format(message, sizeof(message), messageFormat, reason);
    
    // Notify the Server why they are being kicked
    PrintToChat(clientIndex, "[AutoMessage] %s", message);

    // Delayed Kick to ensure the message is received and that they see why they have been Banned/Muted/Gagged
    CreateTimer(2.0, Timer_KickClient, clientIndex, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_KickClient(Handle timer, int clientIndex)
{
    if (IsClientConnected(clientIndex))
    {
        new String:kickCommand[256];
        Format(kickCommand, sizeof(kickCommand), "kick #%d %s", GetClientUserId(clientIndex), "You have been kicked.");
        ServerCommand(kickCommand);
    }
    return Plugin_Stop;
}