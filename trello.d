
module kaleidic.sil.std.extra.trello;

/+
	This file is generated automatically - do not edit or else your changes will be lost.

	Example use from SIL:

		trello.setSecrets()
		a=trello.search({"query":"ALL","cards_limit":1000,"cards_page":1})
		a.cards
+/

import kaleidic.sil.lang.handlers:Handlers;
import kaleidic.sil.lang.types: Variable, SILdoc;
import requests: Request;

shared string trelloAPIURL = "https://api.trello.com";
shared string trelloSecret, trelloAuth;

version (Windows)
{
	immutable string caCertPath;

	shared static this()
	{
		import std.file : thisExePath;
		import std.path : buildPath, dirName;

		caCertPath = dirName(thisExePath).buildPath("cacert.pem");
	}

	auto newRequest()
	{
		auto req = Request();
		req.sslSetCaCert(caCertPath);
		return req;
	}
}

void registerTrello(ref Handlers handlers)
{
	import std.meta:AliasSeq;
	handlers.openModule("trello");
	scope(exit) handlers.closeModule();
	static foreach(F;	AliasSeq!(	setSecrets,	createTokenURI,		openBrowserAuth,		setSecrets))
		handlers.registerHandler!F;
	handlers.registerHandlerHelper;
}

string createTokenURI(string apiKey="", string tokenScope = "read,write,account", string name = "Sil", string expiration = "never")
{
	import std.process: environment;
	import std.format:format;
	if (apiKey.length == 0) apiKey = environment.get("TRELLO_API_KEY","");
	return format!"https://trello.com/1/authorize?expiration=%s&name=%s&scope=%s&response_type=token&key=%s"
			(expiration,name,tokenScope,apiKey);
}

//void
auto openBrowserAuth(string apiKey="", string tokenScope = "read,write,account", string name = "Sil", string expiration = "never")
{
	import std.process: environment;
	if (apiKey.length == 0) apiKey = environment.get("TRELLO_API_KEY","");
	// import kaleidic.sil.std.core.process:openBrowser;
	auto uri = createTokenURI(apiKey,tokenScope,name,expiration);
	return uri; // openBrowser(uri);
}

@SILdoc("set Trello secrets from TRELLO_SECRET and TRELLO_AUTH environmental variables")
string setSecrets()
{
	import std.process: environment;
	import std.exception: enforce;
	trelloSecret = environment.get("TRELLO_API_KEY","");
	enforce(trelloSecret.length > 0, "TRELLO_API_KEY environmental variable must be set");
	trelloAuth = environment.get("TRELLO_AUTH","");
	enforce(trelloAuth.length > 0, "TRELLO_AUTH environmental variable must be set");
	return "Secret has been set to TRELLO_API_KEY and auth to TRELLO_AUTH environment variables";
}

private void del(Request request, string uri, string[string] queryParams = (string[string]).init)
{
	import std.format:format;
	import std.string:join;
	import std.algorithm:canFind;

	string[] queryParamsArray;
	if (queryParams !is null)
	{
		foreach(p;queryParams.byKeyValue)
			queryParamsArray ~= format!"%s=%s"(p.key,p.value);
	}
	auto queryParamString = (queryParamsArray.length>0) ? format!"&%s&"(queryParamsArray.join("&")):"";
	uri ~= (!uri.canFind("?")) ? "?" : "&";
	uri ~= queryParamString;
	request.exec!"DELETE"(uri);
}

private void put(Request request, string uri,string[string] queryParams = (string[string]).init)
{
	import asdf:serializeToJson;
	request.exec!"PUT"(uri,serializeToJson(queryParams));
}
/+
// requests expect content to be provided
private auto post(Request request, string uri)
{
	string[string] emptyQueryParams;
	return request.execute("POST",uri,emptyQueryParams);
}
+/
private string[string] queryParamMap(Variable[string] queryParams)
{
	import std.format:format;
	import std.string:join;
	import std.conv:to;

	string[string] ret;
	foreach(entry;queryParams.byKeyValue)
		ret[entry.key] = entry.value.to!string.stripQuotes;
	return ret;
}
private string stripQuotes(string s)
{
	if (s.length < 3)
		return s;
	if (s[0] == '"' && s[$-1] == '"')
		return s[1..$-1];
	return s;
}

private string queryParamString(Variable[string] queryParams)
{
	import std.format:format;
	import std.string:join;

	string[] queryParamsArray;
	if (queryParams !is null)
	{
		foreach(p;queryParams.byKeyValue)
			queryParamsArray ~= format!"%s=%s"(p.key,p.value);
	}
	return (queryParamsArray.length>0) ? format!"&%s&"(queryParamsArray.join("&")):"";
}

private bool isJson(string result)
{
	import std.string:strip,startsWith;
	import std.algorithm:min;
	result = result[0 .. min(100,result.length)].strip;
	return result.startsWith("{") || result.startsWith("[");
}

private Variable asVariable(string result)
{
	import asdf;
	import kaleidic.sil.std.core.json : toVariable;
	return (result.length > 0 && result.isJson)
		? parseJson(result).toVariable()
		: Variable.init;
}

// FIXME - special cases


@SILdoc(`List the saved searches of a member
		Required Params:
		string      id                            The ID or username of the member

		`)
auto listMemberSavedSearches(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/savedSearches`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}

@SILdoc(`Get a saved search
		Required Params:
		string      id                            The ID or username of the member

		`)
auto savedSearch(string id, string idSearch)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/savedSearches/%s`(trelloAPIURL,id,idSearch));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}

@SILdoc(`Get a specific custom board background
		Required Params:
		string      id                            The ID or username of the member
		string		idBackground				  The ID of the background

		Query Params:
		string      fields                        'all' or a comma-separated list of 'brightness',
		                                          'fullSizeUrl', 'scaled', 'tile'

`)
auto specificCustomBoardBackground(string id, string idBackground, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/customBoardBackgrounds/%s`(trelloAPIURL,id,idBackground));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}

@SILdoc(`Set a member's custom board background
		Required Params:
		string      id                            The ID or username of the member
		string		idBackground                  The ID of the custom board background

		Query Params:
		string      brightness                    One of: 'dark', 'light', 'unknown'
		boolean     tile                          Whether to tile the background

`)
void putMembersCustomBoardBackgrounds(string id, string idBackground, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s//customBoardBackgrounds/%s`(trelloAPIURL,id,idBackground));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}





private void registerHandlerHelper(ref Handlers handlers)
{
	import std.meta: AliasSeq;
	static foreach(F;AliasSeq!(
		actions, actionsBoard, actionsCard, actionsDisplay, actionsList, actionsMember,
		actionsMemberCreator, actionsOrganization, actionsReactions,
		actionsReactionsSummary, batch, boards, boardsActions, boardsBoardPlugins,
		boardsBoardStars, boardsChecklists, boardsLabels, boardsLists, boardsMembers,
		boardsMemberships, boardsPlugins, cards, cardsActions, cardsAttachments,
		cardsBoard, cardsCheckItem, cardsCheckItemStates, cardsChecklists,
		cardsCustomFieldItems, cardsList, cardsMembers, cardsMembersVoted,
		cardsPluginData, cardsStickers, checklists, checklistsBoard, checklistsCards,
		checklistsCheckItems, customFieldsOptions, custom_fields_object, customfields,
		delActions, delActionsReactions, delBoards, delBoardsBoardPlugins,
		delBoardsMembers, delBoardsPowerUps, delCards, delCardsActionsComments,
		delCardsAttachments, delCardsCheckItem, delCardsChecklists, delCardsIdLabels,
		delCardsIdMembers, delCardsMembersVoted, delCardsStickers, delChecklists,
		delChecklistsCheckItems, delCustomfields, delCustomfieldsOptions, delLabels,
		delMembersBoardBackgrounds, delMembersBoardStars, delOrganizations,
		delOrganizationsLogo, delOrganizationsMembers, delOrganizationsMembersAll,
		delOrganizationsPrefsAssociatedDomain, delOrganizationsPrefsOrgInviteRestrict,
		delOrganizationsTags, delTokens, delTokensWebhooks, delWebhooks, emoji,
		enterprises, enterprisesAdmins, enterprisesMembers, enterprisesSignupUrl,
		enterprisesTransferrableOrganization, labels, lists, listsActions, listsBoard,
		listsCards, members, membersActions, membersBoardBackgrounds, membersBoardStars,
		membersBoards, membersBoardsInvited, membersCards, membersCustomEmoji,
		membersNotifications, membersOrganizations, membersOrganizationsInvited,
		membersTokens, membersUploadedStickers, notifications, notificationsBoard,
		notificationsCard, notificationsList, notificationsMember,
		notificationsMemberCreator, notificationsOrganization, openCardsOnBoard,
		organizations, organizationsActions, organizationsBoards, organizationsExports,
		organizationsMembers, organizationsMembersInvited, organizationsMemberships,
		organizationsNewBillableGuests, organizationsPluginData, organizationsTags,
		postActionsReactions, postBoards, postBoardsBoardPlugins,
		postBoardsCalendarKeyGenerate, postBoardsEmailKeyGenerate, postBoardsIdTags,
		postBoardsLabels, postBoardsLists, postBoardsMarkedAsViewed, postBoardsPowerUps,
		postCards, postCardsActionsComments, postCardsAttachments, postCardsChecklists,
		postCardsIdLabels, postCardsIdMembers, postCardsLabels,
		postCardsMarkAssociatedNotificationsRead, postCardsMembersVoted,
		postCardsStickers, postChecklists, postChecklistsCheckItems, postCustomFields,
		postCustomFieldsOptions, postEnterprisesTokens, postLabels, postLists,
		postListsArchiveAllCards, postListsMoveAllCards, postMembersAvatar,
		postMembersBoardBackgrounds, postMembersBoardStars, postMembersCustomEmoji,
		postMembersOneTimeMessagesDismissed, postNotificationsAllRead,
		postOrganizations, postOrganizationsExports, postOrganizationsLogo,
		postOrganizationsTags, postTokensWebhooks, postWebhooks,
		postmembersUploadedStickers, putActions, putActionsText, putBoards,
		putBoardsMembers, putBoardsMemberships, putBoardsMyPrefsEmailPosition,
		putBoardsMyPrefsIdEmailList, putBoardsMyPrefsShowListGuide,
		putBoardsMyPrefsShowSidebar, putBoardsMyPrefsShowSidebarActivity,
		putBoardsMyPrefsShowSidebarBoardActions, putBoardsMyPrefsShowSidebarMembers,
		putCardCustomFieldItem, putCards, putCardsActionsComments, putCardsCheckItem,
		putCardsChecklistCheckItem, putCardsStickers, putChecklists, putChecklistsName,
		putCustomfields, putEnterprisesAdmins, putEnterprisesMembersDeactivated,
		putEnterprisesOrganizations, putLabels, putLabelsColor, putLabelsName, putLists,
		putListsClosed, putListsIdBoard, putListsName, putListsPos, putListsSoftLimit,
		putListsSubscribed, putMembers, putMembersBoardBackgrounds,
		putMembersBoardStars, putNotifications, putNotificationsUnread,
		putOrganizations, putOrganizationsMembers, putOrganizationsMembersDeactivated,
		putTokensWebhooks, putWebhooks, search, searchMembers, tokens, tokensMember,
		tokensWebhooks, webhooks,
	))
	{
		handlers.registerHandler!F;
	}
}

@SILdoc(`Get information about an action
Required Params:
string      id                            The ID of the action

Query Params:
boolean     display                       
boolean     entities                      
string      fields                        'all' or a comma-separated list of action
                                          [fields](ref:action-object)
boolean     member                        
string      member_fields                 'all' or a comma-separated list of member
                                          [fields](ref:member-object)
boolean     memberCreator                 Whether to include the member object for the creator of the
                                          action
string      memberCreator_fields          'all' or a comma-separated list of member
                                          [fields](ref:member-object)

`)
auto actions(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/actions/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a specific property of an action
Required Params:
string      id                            The ID of the action
string      field                         An action [field](ref:action-object)

`)
auto actions(string id, string field)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/actions/%s/%s`(trelloAPIURL,id,field));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the board for an action
Required Params:
string      id                            The ID of the action

Query Params:
string      fields                        'all' or a comma-separated list of board
                                          [fields](ref:board-object)

`)
auto actionsBoard(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/actions/%s/board`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the card for an action
Required Params:
string      id                            The ID of the action

Query Params:
string      fields                        'all' or a comma-separated list of card
                                          [fields](ref:card-object)

`)
auto actionsCard(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/actions/%s/card`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the display information for an action.
Required Params:
string      id                            The ID of the action

`)
auto actionsDisplay(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/actions/%s/display`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the list for an action
Required Params:
string      id                            The ID of the action

Query Params:
string      fields                        'all' or a comma-separated list of list
                                          [fields](ref:list-object)

`)
auto actionsList(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/actions/%s/list`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Gets the member of an action (not the creator)
Required Params:
string      id                            The ID of the action

Query Params:
string      fields                        'all' or a comma-separated list of member
                                          [fields](ref:member-object)

`)
auto actionsMember(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/actions/%s/member`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Gets the member who created the action
Required Params:
string      id                            The ID of the action

Query Params:
string      fields                        'all' or a comma-separated list of member
                                          [fields](ref:member-object)

`)
auto actionsMemberCreator(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/actions/%s/memberCreator`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the organization of an action
Required Params:
string      id                            The ID of the action

Query Params:
string      fields                        'all' or a comma-separated list of organization
                                          [fields](ref:organization-object)

`)
auto actionsOrganization(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/actions/%s/organization`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`List reactions for an action
Required Params:
string      idAction                      The ID of the action

Query Params:
boolean     member                        Whether to load the member as a nested resource. See
                                          [Members Nested Resource](#members-nested-resource)
boolean     emoji                         Whether to load the emoji as a nested resource.

`)
auto actionsReactions(string idAction, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/actions/%s/reactions`(trelloAPIURL,idAction));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get information for a reaction
Required Params:
string      idAction                      The ID of the action
string      id                            The ID of the reaction

Query Params:
boolean     member                        Whether to load the member as a nested resource. See
                                          [Members Nested Resource](#members-nested-resource)
boolean     emoji                         Whether to load the emoji as a nested resource.

`)
auto actionsReactions(string idAction, string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/actions/%s/reactions/%s`(trelloAPIURL,idAction,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`List a summary of all reactions for an action
Required Params:
string      idAction                      The ID of the action

`)
auto actionsReactionsSummary(string idAction)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/actions/%s/reactionsSummary`(trelloAPIURL,idAction));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Query Params:
string      urls                          A list of API routes. Maximum of 10 routes allowed. The
                                          routes should begin with a forward slash and should not
                                          include the API version number - e.g.
                                          "urls=/members/trello,/cards/[cardId]"

`)
auto batch(Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/batch`(trelloAPIURL));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Request a single board.
Required Params:
string      id                            

Query Params:
string      actions                       This is a nested resource. Read more about actions as nested
                                          resources
                                          [here](https://trello.readme.io/reference#actions-nested-resource).
string      boardStars                    Valid values are one of: 'mine' or 'none'.
string      cards                         This is a nested resource. Read more about cards as nested
                                          resources
                                          [here](https://trello.readme.io/reference#cards-nested-resource).
boolean     card_pluginData               Use with the 'cards' param to include card pluginData with
                                          the response
string      checklists                    This is a nested resource. Read more about checklists as
                                          nested resources
                                          [here](https://trello.readme.io/reference#checklists-nested-resource).
boolean     customFields                  This is a nested resource. Read more about custom fields as
                                          nested resources [here](#custom-fields-nested-resource).
string      fields                        The fields of the board to be included in the response.
                                          Valid values: all or a comma-separated list of: closed,
                                          dateLastActivity, dateLastView, desc, descData,
                                          idOrganization, invitations, invited, labelNames,
                                          memberships, name, pinned, powerUps, prefs, shortLink,
                                          shortUrl, starred, subscribed, url
string      labels                        This is a nested resource. Read more about labels as nested
                                          resources
                                          [here](https://trello.readme.io/reference#labels-nested-resource).
string      lists                         This is a nested resource. Read more about lists as nested
                                          resources
                                          [here](https://trello.readme.io/reference#lists-nested-resource).
string      members                       This is a nested resource. Read more about members as nested
                                          resources
                                          [here](https://trello.readme.io/reference#members-nested-resource).
string      memberships                   This is a nested resource. Read more about memberships as
                                          nested resources
                                          [here](https://trello.readme.io/reference#memberships-nested-resource).
string      membersInvited                Returns a list of member objects representing members who
                                          been invited to be a member of the board. One of: admins,
                                          all, none, normal, owners
string      membersInvited_fields         The member fields to be included in the membersInvited
                                          response. Valid values: all or a comma-separated list of:
                                          avatarHash, bio, bioData, confirmed, fullName,
                                          idPremOrgsAdmin, initials, memberType, products, status,
                                          url, username
boolean     pluginData                    Determines whether the pluginData for this board should be
                                          returned. Valid values: true or false.
boolean     organization                  This is a nested resource. Read more about organizations as
                                          nested resources
                                          [here](https://trello.readme.io/reference#organization-nested-resource).
boolean     organization_pluginData       Use with the 'organization' param to include organization
                                          pluginData with the response
boolean     myPrefs                       
boolean     tags                          Also known as collections, tags, refer to the collection(s)
                                          that a Board belongs to.

`)
auto boards(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            The ID of the board.
string      field                         The field you'd like to receive. Valid values: closed,
                                          dateLastActivity, dateLastView, desc, descData,
                                          idOrganization, invitations, invited, labelNames,
                                          memberships, name, pinned, powerUps, prefs, shortLink,
                                          shortUrl, starred, subscribed, url.

`)
auto boards(string id, string field)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/%s`(trelloAPIURL,id,field));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      boardId                       

`)
auto boardsActions(string boardId)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/actions`(trelloAPIURL,boardId));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the enabled Power-Ups on a board
Required Params:
string      id                            The ID of the board

`)
auto boardsBoardPlugins(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/boardPlugins`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      boardId                       

Optional Params:
string      filter                        Valid values: mine, none

`)
auto boardsBoardStars(string boardId, string filter = null)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/boardStars`(trelloAPIURL,boardId));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            The ID of the board

`)
auto boardsChecklists(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/checklists`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            The ID of the board

Query Params:
string      fields                        'all' or a comma-separated list of label
                                          [fields](#label-object)
int         limit                         0 to 1000

`)
auto boardsLabels(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/labels`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            The ID of the board
string      filter                        One of 'all', 'closed', 'none', 'open'

`)
auto boardsLists(string id, string filter)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/lists/%s`(trelloAPIURL,id,filter));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            The ID of the board

Query Params:
string      cards                         One of: 'all', 'closed', 'none', 'open'
string      card_fields                   'all' or a comma-separated list of card
                                          [fields](#card-object)
string      filter                        One of 'all', 'closed', 'none', 'open'
string      fields                        'all' or a comma-separated list of list
                                          [fields](#list-object)

`)
auto boardsLists(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/lists`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the members for a board
Required Params:
string      id                            The ID of the board

`)
auto boardsMembers(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/members`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get information about the memberships users have to the board.
Required Params:
string      id                            The ID of the board

Query Params:
string      filter                        One of 'admins', 'all', 'none', 'normal'
boolean     activity                      Works for premium organizations only.
boolean     orgMemberType                 Shows the type of member to the org the user is. For
                                          instance, an org admin will have a 'orgMemberType' of
                                          'admin'.
boolean     member                        Determines whether to include a nester member object.
string      member_fields                 Fields to show if 'member=true'. Valid values: [nested
                                          member resource
                                          fields](https://developers.trello.com/v1.0/reference#members-nested-resource).

`)
auto boardsMemberships(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/memberships`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`List the Power-Ups for a board
Required Params:
string      id                            The ID of the board

Query Params:
string      filter                        One of: 'enabled' or 'available'

`)
auto boardsPlugins(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/plugins`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a card by its ID
Required Params:
string      id                            The ID of the card

Query Params:
string      fields                        'all' or a comma-separated list of
                                          [fields](ref:card-object). **Defaults**: 'badges,
                                          checkItemStates, closed, dateLastActivity, desc, descData,
                                          due, email, idBoard, idChecklists, idLabels, idList,
                                          idMembers, idShort, idAttachmentCover,
                                          manualCoverAttachment, labels, name, pos, shortUrl, url'
string      actions                       See the [Actions Nested
                                          Resource](ref:actions-nested-resource)
string      attachments                   'true', 'false', or 'cover'
string      attachment_fields             'all' or a comma-separated list of attachment
                                          [fields](ref:attachments)
boolean     members                       Whether to return member objects for members on the card
string      member_fields                 'all' or a comma-separated list of member
                                          [fields](ref:member-object). **Defaults**: 'avatarHash,
                                          fullName, initials, username'
boolean     membersVoted                  Whether to return member objects for members who voted on
                                          the card
string      memberVoted_fields            'all' or a comma-separated list of member
                                          [fields](ref:member-object). **Defaults**: 'avatarHash,
                                          fullName, initials, username'
boolean     checkItemStates               
string      checklists                    Whether to return the checklists on the card. 'all' or
                                          'none'
string      checklist_fields              'all' or a comma-separated list of
                                          'idBoard,idCard,name,pos'
boolean     board                         Whether to return the board object the card is on
string      board_fields                  'all' or a comma-separated list of board
                                          [fields](#board-object). **Defaults**: 'name, desc,
                                          descData, closed, idOrganization, pinned, url, prefs'
boolean     list                          See the [Lists Nested Resource](ref:lists-nested-resource)
boolean     pluginData                    Whether to include pluginData on the card with the response
boolean     stickers                      Whether to include sticker models with the response
string      sticker_fields                'all' or a comma-separated list of sticker
                                          [fields](ref:stickers)
boolean     customFieldItems              Whether to include the customFieldItems

`)
auto cards(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a specific property of a card
Required Params:
string      id                            The id of the card
string      field                         The desired field. One of [fields](ref:card-object)

`)
auto cards(string id, string field)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/%s`(trelloAPIURL,id,field));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`List the actions on a card
Required Params:
string      id                            The ID of the card

`)
auto cardsActions(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/actions`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a specific attachment on a card
Required Params:
string      id                            The ID of the card
string      idAttachment                  The ID of the attachment

Query Params:
string      fields                        'all' or a comma-separated list of attachment
                                          [fields](ref:attachments)

`)
auto cardsAttachments(string id, string idAttachment, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/attachments/%s`(trelloAPIURL,id,idAttachment));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`List the attachments on a card
Required Params:
string      id                            The ID of the card

Optional Params:
string      fields                        'all' or a comma-separated list of attachment
                                          [fields](ref:attachments)
string      filter                        Use 'cover' to restrict to just the cover attachment

`)
auto cardsAttachments(string id, string fields = null, string filter = null)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/attachments`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the board a card is on
Required Params:
string      id                            The ID of the card

Query Params:
string      fields                        'all' or a comma-separated list of board
                                          [fields](#board-object)

`)
auto cardsBoard(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/board`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a specific checkItem on a card
Required Params:
string      id                            The ID of the card
string      idCheckItem                   The ID of the checkitem

Query Params:
string      fields                        'all' or a comma-separated list of
                                          'name,nameData,pos,state,type'

`)
auto cardsCheckItem(string id, string idCheckItem, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/checkItem/%s`(trelloAPIURL,id,idCheckItem));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the completed checklist items on a card
Required Params:
string      id                            The ID of the card

Query Params:
string      fields                        'all' or a comma-separated list of: 'idCheckItem', 'state'

`)
auto cardsCheckItemStates(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/checkItemStates`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the checklists on a card
Required Params:
string      id                            The ID of the card

Query Params:
string      checkItems                    'all' or 'none'
string      checkItem_fields              'all' or a comma-separated list of:
                                          'name,nameData,pos,state,type'
string      filter                        'all' or 'none'
string      fields                        'all' or a comma-separated list of:
                                          'idBoard,idCard,name,pos'

`)
auto cardsChecklists(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/checklists`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the custom field items for a card.
Required Params:
string      id                            The ID of the card

`)
auto cardsCustomFieldItems(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/customFieldItems`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the list a card is in
Required Params:
string      id                            The ID of the card

Query Params:
string      fields                        'all' or a comma-separated list of list
                                          [fields](ref:list-object)

`)
auto cardsList(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/list`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the members on a card
Required Params:
string      id                            The ID of the card

Query Params:
string      fields                        'all' or a comma-separated list of member
                                          [fields](ref:member-object)

`)
auto cardsMembers(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/members`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the members who have voted on a card
Required Params:
string      id                            The ID of the card

Query Params:
string      fields                        'all' or a comma-separated list of member
                                          [fields](ref:member-object)

`)
auto cardsMembersVoted(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/membersVoted`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get any shared pluginData on a card
Required Params:
string      id                            The ID of the card

`)
auto cardsPluginData(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/pluginData`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a specific sticker on a card
Required Params:
string      id                            The ID of the card
string      idSticker                     The ID of the sticker

Query Params:
string      fields                        'all' or a comma-separated list of sticker
                                          [fields](ref:stickers)

`)
auto cardsStickers(string id, string idSticker, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/stickers/%s`(trelloAPIURL,id,idSticker));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the stickers on a card
Required Params:
string      id                            The ID of the card

Query Params:
string      fields                        'all' or a comma-separated list of sticker
                                          [fields](ref:stickers)

`)
auto cardsStickers(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/stickers`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            ID of a checklist.
string      field                         A checklist [field](ref:checklist-object)

`)
auto checklists(string id, string field)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/checklists/%s/%s`(trelloAPIURL,id,field));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            ID of a checklist.

Query Params:
string      cards                         Valid values: 'all', 'closed', 'none', 'open', 'visible'.
                                          Cards is a nested resource. The additional query params
                                          available are documented at [Cards Nested
                                          Resource](ref:cards-nested-resource).
string      checkItems                    The check items on the list to return. One of: 'all',
                                          'none'.
string      checkItem_fields              The fields on the checkItem to return if checkItems are
                                          being returned. 'all' or a comma-separated list of: 'name',
                                          'nameData', 'pos', 'state', 'type'
string      fields                        'all' or a comma-separated list of checklist
                                          [fields](ref:checklist-object)

`)
auto checklists(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/checklists/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            ID of a checklist.

Query Params:
string      fields                        'all' or a comma-separated list of board
                                          [fields](ref:board-object)

`)
auto checklistsBoard(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/checklists/%s/board`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            ID of a checklist.

`)
auto checklistsCards(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/checklists/%s/cards`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            ID of a checklist.

Query Params:
string      filter                        One of: 'all', 'none'.
string      fields                        One of: 'all', 'name', 'nameData', 'pos', 'state', 'type'.

`)
auto checklistsCheckItems(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/checklists/%s/checkItems`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            ID of a checklist.
string      idCheckItem                   ID of the check item to retrieve.

Query Params:
string      fields                        One of: 'all', 'name', 'nameData', 'pos', 'state', 'type'.

`)
auto checklistsCheckItems(string id, string idCheckItem, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/checklists/%s/checkItems/%s`(trelloAPIURL,id,idCheckItem));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the options of a drop down Custom Field
Required Params:
string      id                            ID of the customfield.

`)
auto customFieldsOptions(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/customFields/%s/options`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            ID of the customfielditem.
string      idCustomFieldOption           ID of the customfieldoption to retrieve.

`)
auto customFieldsOptions(string id, string idCustomFieldOption)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/customFields/%s/options/%s`(trelloAPIURL,id,idCustomFieldOption));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            ID of the customfield to retrieve.

`)
auto custom_fields_object(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/customfields/%s`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            ID of the customfield to retrieve.

`)
auto customfields(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/customfields/%s`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Delete a comment action
Required Params:
string      id                            The ID of the commentCard action to delete

`)
void delActions(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/actions/%s`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Deletes a reaction
Required Params:
string      idAction                      The ID of the action
string      id                            The ID of the reaction

`)
void delActionsReactions(string idAction, string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/actions/%s/reactions/%s`(trelloAPIURL,idAction,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Delete a board.
Required Params:
string      id                            The id of the board to delete

`)
void delBoards(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Disable a Power-Up on a board
Required Params:
string      id                            The ID of the board
string      idPlugin                      The ID of the Power-Up to disable

`)
void delBoardsBoardPlugins(string id, string idPlugin)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/boardPlugins/%s`(trelloAPIURL,id,idPlugin));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`
Required Params:
string      id                            The id of the board to update
string      idMember                      The id, username, or organization name of the user to be
                                          removed from the board.

`)
void delBoardsMembers(string id, string idMember)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/members/%s`(trelloAPIURL,id,idMember));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`
Required Params:
string      id                            The id of the board to update
string      powerUp                       The Power-Up to be enabled on the board. One of: 'calendar',
                                          'cardAging', 'recap', 'voting'.

`)
void delBoardsPowerUps(string id, string powerUp)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/powerUps/%s`(trelloAPIURL,id,powerUp));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Delete a card
Required Params:
string      id                            The ID of the card

`)
void delCards(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Delete a comment
Required Params:
string      id                            The ID of the card
string      idAction                      The ID of the comment action

`)
void delCardsActionsComments(string id, string idAction)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/actions/%s/comments`(trelloAPIURL,id,idAction));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Delete an attachment
Required Params:
string      id                            The ID of the card
string      idAttachment                  The ID of the attachment to delete

`)
void delCardsAttachments(string id, string idAttachment)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/attachments/%s`(trelloAPIURL,id,idAttachment));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Delete a checklist item
Required Params:
string      id                            The ID of the card
string      idCheckItem                   The ID of the checklist item to delete

`)
void delCardsCheckItem(string id, string idCheckItem)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/checkItem/%s`(trelloAPIURL,id,idCheckItem));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Delete a checklist from a card
Required Params:
string      id                            The ID of the card
string      idChecklist                   The ID of the checklist to delete

`)
void delCardsChecklists(string id, string idChecklist)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/checklists/%s`(trelloAPIURL,id,idChecklist));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Remove a label from a card
Required Params:
string      id                            The ID of the card
string      idLabel                       The ID of the label to remove

`)
void delCardsIdLabels(string id, string idLabel)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/idLabels/%s`(trelloAPIURL,id,idLabel));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Remove a member from a card
Required Params:
string      id                            The ID of the card
string      idMember                      The ID of the member to remove from the card

`)
void delCardsIdMembers(string id, string idMember)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/idMembers/%s`(trelloAPIURL,id,idMember));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Remove a member's vote from a card
Required Params:
string      id                            The ID of the card
string      idMember                      The ID of the member whose vote to remove

`)
void delCardsMembersVoted(string id, string idMember)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/membersVoted/%s`(trelloAPIURL,id,idMember));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Remove a sticker from the card
Required Params:
string      id                            The ID of the card
string      idSticker                     The ID of the sticker to remove from the card

`)
void delCardsStickers(string id, string idSticker)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/stickers/%s`(trelloAPIURL,id,idSticker));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Delete a checklist
Required Params:
string      id                            ID of a checklist.

`)
void delChecklists(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/checklists/%s`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Remove an item from a checklist
Required Params:
string      id                            ID of a checklist.
string      idCheckItem                   ID of the checklist item to delete.

`)
void delChecklistsCheckItems(string id, string idCheckItem)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/checklists/%s/checkItems/%s`(trelloAPIURL,id,idCheckItem));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Delete a Custom Field from a board.
Required Params:
string      id                            ID of the customfield to delete.

`)
void delCustomfields(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/customfields/%s`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Delete an option from a Custom Field dropdown.
Required Params:
string      id                            ID of the customfielditem.
string      idCustomFieldOption           ID of the customfieldoption to delete.

`)
void delCustomfieldsOptions(string id, string idCustomFieldOption)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/customfields/%s/options/%s`(trelloAPIURL,id,idCustomFieldOption));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Delete a label by ID.
Required Params:
string      id                            The ID of the label to delete.

`)
void delLabels(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/labels/%s`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Delete a board background
Required Params:
string      id                            The ID or username of the member
string      idBackground                  The ID of the board background to delete

`)
void delMembersBoardBackgrounds(string id, string idBackground)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/boardBackgrounds/%s`(trelloAPIURL,id,idBackground));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Unstar a board
Required Params:
string      id                            The ID or username of the member
string      idStar                        The ID of the board star to remove

`)
void delMembersBoardStars(string id, string idStar)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/boardStars/%s`(trelloAPIURL,id,idStar));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Delete a team
Required Params:
string      id                            The ID or name of the organization

`)
void delOrganizations(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Delete a the logo from a team
Required Params:
string      id                            The ID or name of the organization

`)
void delOrganizationsLogo(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/logo`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Remove a member from a team
Required Params:
string      id                            The ID or name of the organization
string      idMember                      The ID of the member to remove from the team

`)
void delOrganizationsMembers(string id, string idMember)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/members/%s`(trelloAPIURL,id,idMember));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Remove a member from a team and from all team boards
Required Params:
string      id                            The ID or name of the organization
string      idMember                      The ID of the member to remove from the team

`)
void delOrganizationsMembersAll(string id, string idMember)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/members/%s/all`(trelloAPIURL,id,idMember));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Remove the associated Google Apps domain from a team
Required Params:
string      id                            The ID or name of the organization

`)
void delOrganizationsPrefsAssociatedDomain(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/prefs/associatedDomain`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Remove the email domain restriction on who can be invited to the team
Required Params:
string      id                            The ID or name of the organization

`)
void delOrganizationsPrefsOrgInviteRestrict(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/prefs/orgInviteRestrict`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Delete an organization's tag
Required Params:
string      id                            The ID or name of the organization
string      idTag                         The ID of the tag to delete

`)
void delOrganizationsTags(string id, string idTag)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/tags/%s`(trelloAPIURL,id,idTag));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Delete a token.
Required Params:
string      token                         

`)
void delTokens(string token)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/tokens/%s/`(trelloAPIURL,token));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Delete a webhook created with given token.
Required Params:
string      token                         
string      idWebhook                     ID of the [webhook](ref:webhooks) to delete.

`)
void delTokensWebhooks(string token, string idWebhook)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/tokens/%s/webhooks/%s`(trelloAPIURL,token,idWebhook));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`Delete a webhook by ID.
Required Params:
string      id                            ID of the webhook to delete.

`)
void delWebhooks(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/webhooks/%s`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().del(url,queryParams.queryParamMap);
}


@SILdoc(`List available emoji
Query Params:
string      locale                        The locale to return emoji descriptions and names in.
                                          Defaults to the logged in member's locale.
boolean     spritesheets                  'true' to return spritesheet URLs in the response

`)
auto emoji(Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/emoji`(trelloAPIURL));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get an enterprise by its ID.
Required Params:
string      id                            ID of the enterprise to retrieve.

Query Params:
string      fields                        Comma-separated list of: 'id', 'name', 'displayName',
                                          'prefs', 'ssoActivationFailed', 'idAdmins', 'idMembers'
                                          (Note that the members array returned will be paginated if
                                          'members' is 'normal' or 'admins'. Pagination can be
                                          controlled with member_startIndex, etc, but the API response
                                          will not contain the total available result count or
                                          pagination status data. Read the SCIM documentation [here]()
                                          for more information on filtering), 'idOrganizations',
                                          'products', 'userTypes', 'idMembers', 'idOrganizations'
string      members                       One of: 'none', 'normal', 'admins', 'owners', 'all'
string      member_fields                 One of: 'avatarHash', 'fullName', 'initials', 'username'
string      member_filter                 Pass a [SCIM-style
                                          query](https://developers.trello.com/v1.0/reference#section-parameters)
                                          to filter members. This takes precedence over the
                                          all/normal/admins value of members. If any of the member_*
                                          args are set, the member array will be paginated.
string      member_sort                   This parameter expects a
                                          [SCIM-style](https://developers.trello.com/v1.0/reference#section-parameters)
                                          sorting value prefixed by a '-' to sort descending. If no
                                          '-' is prefixed, it will be sorted ascending. Note that the
                                          members array returned will be paginated if 'members' is
                                          'normal' or 'admins'. Pagination can be controlled with
                                          member_startIndex, etc, but the API response will not
                                          contain the total available result count or pagination
                                          status data.
string      member_sortBy                 Deprecated: Please use member_sort. This parameter expects a
                                          [SCIM-style sorting
                                          value](https://developers.trello.com/v1.0/reference#section-parameters).
                                          Note that the members array returned will be paginated if
                                          'members' is 'normal' or 'admins'. Pagination can be
                                          controlled with 'member_startIndex', etc, and the API
                                          response's header will contain the total count and
                                          pagination state.
string      member_sortOrder              Deprecated: Please use member_sort. One of: 'ascending',
                                          'descending', 'asc', 'desc'
int         member_startIndex             Any integer between 0 and 100.
int         member_count                  0 to 100
string      organizations                 One of: 'none', 'members', 'public', 'all'
string      organization_fields           Any valid value that the [nested organization field
                                          resource]() accepts.
boolean     organization_paid_accounts    
string      organization_memberships      Comma-seperated list of: 'me', 'normal', 'admin', 'active',
                                          'deactivated'

`)
auto enterprises(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/enterprises/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get an enterprise's admin members.
Required Params:
string      id                            ID of the enterprise to retrieve.

Query Params:
string      fields                        Any valid value that the [nested member field resource]()
                                          accepts.

`)
auto enterprisesAdmins(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/enterprises/%s/admins`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a specific member of an enterprise by ID.
Required Params:
string      id                            ID of the enterprise to retrieve.
string      idMember                      An ID of a member resource.

Query Params:
string      fields                        A comma separated list of any valid values that the [nested
                                          member field resource]() accepts.
string      organization_fields           Any valid value that the [nested organization field
                                          resource](https://developers.trello.com/v1.0/reference#organizations-nested-resource)
                                          accepts.
string      board_fields                  Any valid value that the [nested board
                                          resource](https://developers.trello.com/v1.0/reference#boards-nested-resource)
                                          accepts.

`)
auto enterprisesMembers(string id, string idMember, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/enterprises/%s/members/%s`(trelloAPIURL,id,idMember));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the members of an enterprise.
Required Params:
string      id                            ID of the enterprise to retrieve.

Query Params:
string      fields                        A comma-seperated list of valid [member fields](member).
string      filter                        Pass a [SCIM-style
                                          query](https://developers.trello.com/v1.0/reference#section-parameters)
                                          to filter members. This takes precedence over the
                                          all/normal/admins value of members. If any of the below
                                          member_* args are set, the member array will be paginated.
string      sort                          This parameter expects a
                                          [SCIM-style](https://developers.trello.com/v1.0/reference#section-parameters)
                                          sorting value prefixed by a '-' to sort descending. If no
                                          '-' is prefixed, it will be sorted ascending. Note that the
                                          members array returned will be paginated if 'members' is
                                          'normal' or 'admins'. Pagination can be controlled with
                                          member_startIndex, etc, but the API response will not
                                          contain the total available result count or pagination
                                          status data.
string      sortBy                        Deprecated: Please use 'sort' instead. This parameter
                                          expects a
                                          [SCIM-style](https://developers.trello.com/v1.0/reference#section-parameters)
                                          sorting value. Note that the members array returned will be
                                          paginated if 'members' is 'normal' or 'admins'. Pagination
                                          can be controlled with member_startIndex, etc, but the API
                                          response will not contain the total available result count
                                          or pagination status data.
string      sortOrder                     Deprecated: Please use 'sort' instead. One of: 'ascending',
                                          'descending', 'asc', 'desc'.
int         startIndex                    Any integer between 0 and 9999.
string      count                         [SCIM-style
                                          filter](https://developers.trello.com/v1.0/reference#section-parameters).
string      organization_fields           Any valid value that the [nested organization field
                                          resource](https://developers.trello.com/v1.0/reference#organizations-nested-resource)
                                          accepts.
string      board_fields                  Any valid value that the [nested board
                                          resource](https://developers.trello.com/v1.0/reference#boards-nested-resource)
                                          accepts.

`)
auto enterprisesMembers(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/enterprises/%s/members`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the signup URL for an enterprise.
Required Params:
string      id                            ID of the enterprise to retrieve.

Query Params:
boolean     authenticate                  
boolean     confirmationAccepted          
string      returnUrl                     Any valid URL.
boolean     tosAccepted                   Designates whether the user has seen/consented to the Trello
                                          ToS prior to being redirected to the enterprise signup
                                          page/their IdP.

`)
auto enterprisesSignupUrl(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/enterprises/%s/signupUrl`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get whether an organization can be transferred to an enterprise.
Required Params:
string      id                            ID of the enterprise to retrieve.
string      idOrganization                An ID of an Organization resource.

`)
auto enterprisesTransferrableOrganization(string id, string idOrganization)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/enterprises/%s/transferrable/organization/%s`(trelloAPIURL,id,idOrganization));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get information about a label by ID.
Required Params:
string      id                            

Query Params:
string      fields                        all or a comma-separated list of [fields](#label-object)

`)
auto labels(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/labels/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a specific property of a list
Required Params:
string      id                            The ID of the list
string      field                         The field to return. See [fields](#list-object)

`)
auto lists(string id, string field)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/lists/%s/%s`(trelloAPIURL,id,field));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get information about a list
Required Params:
string      id                            The ID of the list

Query Params:
string      fields                        'all' or a comma separated list of [fields](#list-object)

`)
auto lists(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/lists/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`List the actions on a list
Required Params:
string      id                            The ID of the list

`)
auto listsActions(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/lists/%s/actions`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the board a list is on
Required Params:
string      id                            The ID of the list

Query Params:
string      fields                        'all' or a comma-separated list of board
                                          [fields](#board-object)

`)
auto listsBoard(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/lists/%s/board`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`List the cards in a list
Required Params:
string      id                            The ID of the list

`)
auto listsCards(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/lists/%s/cards`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a particular property of a member
Required Params:
string      id                            The ID or username of the member
string      field                         One of the member [fields](ref:member-object)

`)
auto members(string id, string field)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/%s`(trelloAPIURL,id,field));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a member
Required Params:
string      id                            The ID or username of the member

Query Params:
string      actions                       See the [Actions Nested
                                          Resource](ref:actions-nested-resource)
string      boards                        See the [Boards Nested
                                          Resource](ref:section-objectidboardsopen)
string      boardBackgrounds              One of: 'all', 'custom', 'default', 'none', 'premium'
string      boardsInvited                 'all' or a comma-separated list of: closed, members, open,
                                          organization, pinned, public, starred, unpinned
string      boardsInvited_fields          'all' or a comma-separated list of board
                                          [fields](ref:board-object)
boolean     boardStars                    
string      cards                         See the [Cards Nested Resource](ref:cards-nested-resource)
                                          for additional options
string      customBoardBackgrounds        'all' or 'none'
string      customEmoji                   'all' or 'none'
string      customStickers                'all' or 'none'
string      fields                        'all' or a comma-separated list of member
                                          [fields](ref:member-object)
string      notifications                 See the [Notifications Nested
                                          Resource](ref:section-objectidnotificationsall)
string      organizations                 One of: 'all', 'members', 'none', 'public'
string      organization_fields           'all' or a comma-separated list of organization
                                          [fields](ref:organization-object)
boolean     organization_paid_account     
string      organizationsInvited          One of: 'all', 'members', 'none', 'public'
string      organizationsInvited_fields   'all' or a comma-separated list of organization
                                          [fields](ref:organization-object)
boolean     paid_account                  
boolean     savedSearches                 
string      tokens                        'all' or 'none'

`)
auto members(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`List the actions for a member
Required Params:
string      id                            The ID or username of the member

`)
auto membersActions(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/actions`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a member's board background
Required Params:
string      id                            The ID or username of the member
string      idBackground                  The ID of the board background

Query Params:
string      fields                        'all' or a comma-separated list of: 'brightness',
                                          'fullSizeUrl', 'scaled', 'tile'

`)
auto membersBoardBackgrounds(string id, string idBackground, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/boardBackgrounds/%s`(trelloAPIURL,id,idBackground));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a member's custom board backgrounds
Required Params:
string      id                            The ID or username of the member

Query Params:
string      filter                        One of: 'all', 'custom', 'default', 'none', 'premium'

`)
auto membersBoardBackgrounds(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/boardBackgrounds`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a specific boardStar
Required Params:
string      id                            The ID or username of the member
string      idStar                        The ID of the board star

`)
auto membersBoardStars(string id, string idStar)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/boardStars/%s`(trelloAPIURL,id,idStar));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`List a member's board stars
Required Params:
string      id                            The ID or username of the member

`)
auto membersBoardStars(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/boardStars`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Lists the boards that the user is a member of.
Required Params:
string      id                            The ID or username of the member

Query Params:
string      filter                        'all' or a comma-separated list of: 'closed', 'members',
                                          'open', 'organization', 'public', 'starred'
string      fields                        'all' or a comma-separated list of board
                                          [fields](ref:board-object)
string      lists                         Which lists to include with the boards. One of: 'all',
                                          'closed', 'none', 'open'
string      memberships                   'all' or a comma-separated list of 'active', 'admin',
                                          'deactivated', 'me', 'normal'
boolean     organization                  Whether to include the organization object with the boards
string      organization_fields           'all' or a comma-separated list of organization
                                          [fields](ref:organization-object)

`)
auto membersBoards(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/boards`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the boards the member has been invited to
Required Params:
string      id                            The ID or username of the member

Query Params:
string      fields                        'all' or a comma-separated list of board
                                          [fields](ref:board-object)

`)
auto membersBoardsInvited(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/boardsInvited`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Gets the cards a member is on
Required Params:
string      id                            The ID or username of the member

Query Params:
string      filter                        One of: 'all', 'closed', 'none', 'open', 'visible'

`)
auto membersCards(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/cards`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a member's uploaded custom emoji
Required Params:
string      id                            The ID or username of the member

`)
auto membersCustomEmoji(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/customEmoji`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a custom emoji
Required Params:
string      id                            The ID or username of the member
string      idEmoji                       The ID of the custom emoji

Query Params:
string      fields                        'all' or a comma-separated list of 'name', 'url'

`)
auto membersCustomEmoji(string id, string idEmoji, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/customEmoji/%s`(trelloAPIURL,id,idEmoji));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a member's notifications
Required Params:
string      id                            The ID or username of the member

Query Params:
boolean     entities                      
boolean     display                       
string      filter                        
string      read_filter                   One of: 'all', 'read', 'unread'
string      fields                        'all' or a comma-separated list of notification
                                          [fields](ref:notification-object)
int         limit                         Max 1000
int         page                          Max 100
string      before                        A notification ID
string      since                         A notification ID
boolean     memberCreator                 
string      memberCreator_fields          'all' or a comma-separated list of member
                                          [fields](ref:member-object)

`)
auto membersNotifications(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/notifications`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a member's teams
Required Params:
string      id                            The ID or username of the member

Query Params:
string      filter                        One of: 'all', 'members', 'none', 'public' (Note: 'members'
                                          filters to only private teams)
string      fields                        'all' or a comma-separated list of organization
                                          [fields](ref:organization-object)
boolean     paid_account                  

`)
auto membersOrganizations(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/organizations`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a member's teams they have been invited to
Required Params:
string      id                            The ID or username of the member

Query Params:
string      fields                        'all' or a comma-separated list of organization
                                          [fields](ref:organization-object)

`)
auto membersOrganizationsInvited(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/organizationsInvited`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`List a members app tokens
Required Params:
string      id                            The ID or username of the member

Query Params:
boolean     webhooks                      Whether to include webhooks

`)
auto membersTokens(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/tokens`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a member's uploaded stickers
Required Params:
string      id                            The ID or username of the member

`)
auto membersUploadedStickers(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/customStickers`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            The ID of the notification

Query Params:
boolean     board                         Whether to include the board object
string      board_fields                  'all' or a comma-separated list of board
                                          [fields](ref:board-object)
boolean     card                          Whether to include the card object
string      card_fields                   'all' or a comma-separated list of card
                                          [fields](ref:card-object)
boolean     display                       Whether to include the display object with the results
boolean     entities                      Whether to include the entities object with the results
string      fields                        'all' or a comma-separated list of notification
                                          [fields](ref:notification-object)
boolean     list                          Whether to include the list object
boolean     member                        Whether to include the member object
string      member_fields                 'all' or a comma-separated list of member
                                          [fields](ref:member-object)
boolean     memberCreator                 Whether to include the member object of the creator
string      memberCreator_fields          'all' or a comma-separated list of member
                                          [fields](ref:member-object)
boolean     organization                  Whether to include the organization object
string      organization_fields           'all' or a comma-separated list of organization
                                          [fields](ref:organization-object)

`)
auto notifications(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/notifications/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a specific property of a notification
Required Params:
string      id                            The ID of the notification
string      field                         A notification [field](ref:notifcation-object)

`)
auto notifications(string id, string field)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/notifications/%s/%s`(trelloAPIURL,id,field));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the board a notification is associated with
Required Params:
string      id                            The ID of the notification

Query Params:
string      fields                        'all' or a comma-separated list of
                                          board[fields](ref:board-object)

`)
auto notificationsBoard(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/notifications/%s/board`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the card a notification is associated with
Required Params:
string      id                            The ID of the notification

Query Params:
string      fields                        'all' or a comma-separated list of card
                                          [fields](ref:card-object)

`)
auto notificationsCard(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/notifications/%s/card`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the list a notification is associated with
Required Params:
string      id                            The ID of the notification

Query Params:
string      fields                        'all' or a comma-separated list of list
                                          [fields](ref:list-object)

`)
auto notificationsList(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/notifications/%s/list`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the member (not the creator) a notification is about
Required Params:
string      id                            The ID of the notification

Query Params:
string      fields                        'all' or a comma-separated list of member
                                          [fields](ref:member-object)

`)
auto notificationsMember(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/notifications/%s/member`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the member who created the notification
Required Params:
string      id                            The ID of the notification

Query Params:
string      fields                        'all' or a comma-separated list of member
                                          [fields](ref:member-object)

`)
auto notificationsMemberCreator(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/notifications/%s/memberCreator`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get the organization a notification is associated with
Required Params:
string      id                            The ID of the notification

Query Params:
string      fields                        'all' or a comma-separated list of organization
                                          [fields](ref:organization-object)

`)
auto notificationsOrganization(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/notifications/%s/organization`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Fetch open cards on a board
Required Params:
string      id                            

`)
auto openCardsOnBoard(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/cards`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            The ID or name of the organization
string      field                         An organization [field](ref:organization-object)

`)
auto organizations(string id, string field)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/%s`(trelloAPIURL,id,field));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            The ID or name of the organization

`)
auto organizations(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`List the actions on a team
Required Params:
string      id                            The ID or name of the organization

`)
auto organizationsActions(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/actions`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`List the boards in a team
Required Params:
string      id                            The ID or name of the organization

Query Params:
string      filter                        'all' or a comma-separated list of: 'open', 'closed',
                                          'members', 'organization', 'public'
string      fields                        'all' or a comma-separated list of board
                                          [fields](ref:board-object)

`)
auto organizationsBoards(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/boards`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Retrieve the exports that exist for the given organization
Required Params:
string      id                            The ID or name of the organization

`)
auto organizationsExports(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/exports`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`List the members in a team
Required Params:
string      id                            The ID or name of the organization

`)
auto organizationsMembers(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/members`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`List the members with pending invites to a team
Required Params:
string      id                            The ID or name of the organization

Query Params:
string      fields                        'all' or a comma-separated list of member
                                          [fields](ref:member-object)

`)
auto organizationsMembersInvited(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/membersInvited`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`List the memberships of a team
Required Params:
string      id                            The ID or name of the organization
string      idMembership                  The ID of the membership to load

Query Params:
boolean     member                        Whether to include the member object in the response

`)
auto organizationsMemberships(string id, string idMembership, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/memberships/%s`(trelloAPIURL,id,idMembership));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`List the memberships of a team
Required Params:
string      id                            The ID or name of the organization

Query Params:
string      filter                        'all' or a comma-separated list of: 'active', 'admin',
                                          'deactivated', 'me', 'normal'
boolean     member                        Whether to include the member objects with the memberships

`)
auto organizationsMemberships(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/memberships`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Used to check whether the given board has new billable guests on it.
Required Params:
string      id                            The ID or name of the organization
string      idBoard                       The ID of the board to check for new billable guests.

`)
auto organizationsNewBillableGuests(string id, string idBoard)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/newBillableGuests/%s`(trelloAPIURL,id,idBoard));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get organization scoped pluginData on this team
Required Params:
string      id                            The ID or name of the organization

`)
auto organizationsPluginData(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/pluginData`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`List the organization's collections
Required Params:
string      id                            The ID or name of the organization

`)
auto organizationsTags(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/tags`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Adds a new reaction to an action
Required Params:
string      idAction                      The ID of the action

Optional Params:
string      shortName                     The primary 'shortName' of the emoji to add. See
                                          [/emoji](#emoji)
string      skinVariation                 The 'skinVariation' of the emoji to add. See
                                          [/emoji](#emoji)
string      native                        The emoji to add as a native unicode emoji. See
                                          [/emoji](#emoji)
string      unified                       The 'unified' value of the emoji to add. See
                                          [/emoji](#emoji)

`)
auto postActionsReactions(string idAction, string shortName = null, string skinVariation = null, string native = null, string unified = null)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/actions/%s/reactions`(trelloAPIURL,idAction));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Create a new board.
Query Params:
string      name                          The new name for the board. 1 to 16384 characters long.
boolean     defaultLabels                 Determines whether to use the default set of labels.
boolean     defaultLists                  Determines whether to add the default set of lists to a
                                          board (To Do, Doing, Done). It is ignored if 'idBoardSource'
                                          is provided.
string      desc                          A new description for the board, 0 to 16384 characters long
string      idOrganization                The id or name of the team the board should belong to.
string      idBoardSource                 The id of a board to copy into the new board.
string      keepFromSource                To keep cards from the original board pass in the value
                                          'cards'
string      powerUps                      The Power-Ups that should be enabled on the new board. One
                                          of: 'all', 'calendar', 'cardAging', 'recap', 'voting'.
string      prefs_permissionLevel         The permissions level of the board. One of: 'org',
                                          'private', 'public'.
string      prefs_voting                  Who can vote on this board. One of 'disabled', 'members',
                                          'observers', 'org', 'public'.
string      prefs_comments                Who can comment on cards on this board. One of: 'disabled',
                                          'members', 'observers', 'org', 'public'.
string      prefs_invitations             Determines what types of members can invite users to join.
                                          One of: 'admins', 'members'.
boolean     prefs_selfJoin                Determines whether users can join the boards themselves or
                                          whether they have to be invited.
boolean     prefs_cardCovers              Determines whether card covers are enabled.
string      prefs_background              The id of a custom background or one of: 'blue', 'orange',
                                          'green', 'red', 'purple', 'pink', 'lime', 'sky', 'grey'.
string      prefs_cardAging               Determines the type of card aging that should take place on
                                          the board if card aging is enabled. One of: 'pirate',
                                          'regular'.

`)
auto postBoards(Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/`(trelloAPIURL));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Enable a Power-Up on a board
Required Params:
string      id                            The ID of the board

Query Params:
string      idPlugin                      The ID of the Power-Up to enable

`)
auto postBoardsBoardPlugins(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/boardPlugins`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Create a new board.
Required Params:
string      id                            The id of the board to update

`)
auto postBoardsCalendarKeyGenerate(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/calendarKey/generate`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            The id of the board to update

`)
auto postBoardsEmailKeyGenerate(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/emailKey/generate`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            The id of the board to update

Query Params:
string      value                         The id of a tag from the organization to which this board
                                          belongs.

`)
auto postBoardsIdTags(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/idTags`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            The id of the board to update

Query Params:
string      name                          The name of the label to be created. 1 to 16384 characters
                                          long.
string      color                         Sets the color of the new label. Valid values are a label
                                          color or 'null'.

`)
auto postBoardsLabels(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/labels`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            The id of the board to update

Query Params:
string      name                          The name of the list to be created. 1 to 16384 characters
                                          long.
string      pos                           Determines the position of the list. Valid values: 'top',
                                          'bottom', or a positive number.

`)
auto postBoardsLists(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/lists`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            The id of the board to update

`)
auto postBoardsMarkedAsViewed(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/markedAsViewed`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            The id of the board to update

Query Params:
string      value                         The Power-Up to be enabled on the board. One of: 'calendar',
                                          'cardAging', 'recap', 'voting'.

`)
auto postBoardsPowerUps(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/powerUps`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Create a new card
Query Params:
string      name                          The name for the card
string      desc                          The description for the card
string      pos                           The position of the new card. 'top', 'bottom', or a positive
                                          float
datetime    due                           A due date for the card
boolean     dueComplete                   
string      idList                        The ID of the list the card should be created in
string      idMembers                     Comma-separated list of member IDs to add to the card
string      idLabels                      Comma-separated list of label IDs to add to the card
string      urlSource                     A URL starting with 'http://' or 'https://'
file        fileSource                    
string      idCardSource                  The ID of a card to copy into the new card
string      keepFromSource                If using 'idCardSource' you can specify which properties to
                                          copy over. 'all' or comma-separated list of:
                                          'attachments,checklists,comments,due,labels,members,stickers'
string      address                       For use with/by the Map Power-Up
string      locationName                  For use with/by the Map Power-Up
string      coordinates                   For use with/by the Map Power-Up. Should take the form
                                          latitude,longitude

`)
auto postCards(Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards`(trelloAPIURL));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Add a new comment to a card
Required Params:
string      id                            The ID of the card

Query Params:
string      text                          The comment

`)
auto postCardsActionsComments(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/actions/comments`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Add an attachment to a card
Required Params:
string      id                            The ID of the card

Query Params:
string      name                          The name of the attachment. Max length 256.
file        file                          The file to attach, as multipart/form-data
string      mimeType                      The mimeType of the attachment. Max length 256
string      url                           A URL to attach. Must start with 'http://' or 'https://'

`)
auto postCardsAttachments(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/attachments`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Create a new checklist on a card
Required Params:
string      id                            The ID of the card

Query Params:
string      name                          The name of the checklist
string      idChecklistSource             The ID of a source checklist to copy into the new one
string      pos                           The position of the checklist on the card. One of: 'top',
                                          'bottom', or a positive number.

`)
auto postCardsChecklists(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/checklists`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Add a label to a card
Required Params:
string      id                            The ID of the card

Query Params:
string      value                         The ID of the label to add

`)
auto postCardsIdLabels(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/idLabels`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Add a member to a card
Required Params:
string      id                            The ID of the card

Query Params:
string      value                         The ID of the member to add to the card

`)
auto postCardsIdMembers(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/idMembers`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Add a new label to a card
Required Params:
string      id                            The ID of the card

Query Params:
string      color                         A valid label color or 'null'. See
                                          [labels](ref:label-object)
string      name                          A name for the label

`)
auto postCardsLabels(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/labels`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Mark notifications about this card as read
Required Params:
string      id                            The ID of the card

`)
auto postCardsMarkAssociatedNotificationsRead(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/markAssociatedNotificationsRead`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Vote on the card
Required Params:
string      id                            The ID of the card

Query Params:
string      value                         The ID of the member to vote 'yes' on the card

`)
auto postCardsMembersVoted(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/membersVoted`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Add a sticker to a card
Required Params:
string      id                            The ID of the card

Query Params:
string      image                         For custom stickers, the id of the sticker. For default
                                          stickers, the string identifier (like 'taco-cool', see
                                          below)
float       top                           The top position of the sticker, from -60 to 100
float       left                          The left position of the sticker, from -60 to 100
int         zIndex                        The z-index of the sticker
float       rotate                        The rotation of the sticker

`)
auto postCardsStickers(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/stickers`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Query Params:
string      idCard                        The ID of the card that the checklist should be added to.
string      name                          The name of the checklist. Should be a string of length 1 to
                                          16384.
string      pos                           The position of the checklist on the card. One of: 'top',
                                          'bottom', or a positive number.
string      idChecklistSource             The ID of a checklist to copy into the new checklist.

`)
auto postChecklists(Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/checklists`(trelloAPIURL));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`
Required Params:
string      id                            ID of a checklist.

Query Params:
string      name                          The name of the new check item on the checklist. Should be a
                                          string of length 1 to 16384.
string      pos                           The position of the check item in the checklist. One of:
                                          'top', 'bottom', or a positive number.
boolean     checked                       Determines whether the check item is already checked when
                                          created.

`)
auto postChecklistsCheckItems(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/checklists/%s/checkItems`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Create a new Custom Field on a board.
Required Params:
string      idModel                       The ID of the model for which the Custom Field is being
                                          defined. This should always be the ID of a board.
string      modelType                     The type of model that the Custom Field is being defined on.
                                          This should always be 'board'.
string      name                          
string      type                          
string      pos                           

Optional Params:
string      options                       
boolean     display_cardFront             Whether this custom field should be shown on the front of
                                          cards

`)
auto postCustomFields(string idModel, string modelType, string name, string type, string pos, string options = null, bool display_cardFront = false)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/customFields`(trelloAPIURL));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Add an option to a dropdown Custom Field
Required Params:
string      id                            ID of the customfield.

`)
auto postCustomFieldsOptions(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/customFields/%s/options`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Generate an auth token for an enterprise.
Required Params:
string      id                            ID of the enterprise to retrieve.

Query Params:
string      expiration                    One of: '1hour', '1day', '30days', 'never'

`)
auto postEnterprisesTokens(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/enterprises/%s/tokens`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Create a new label on a board.
Query Params:
string      name                          Name for the label
string      color                         The color for the label. See [fields](#label-object) for
                                          color options.
string      idBoard                       The ID of the board to create the label on.

`)
auto postLabels(Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/labels`(trelloAPIURL));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Create a new list on a board
Query Params:
string      name                          Name for the list
string      idBoard                       The long ID of the board the list should be created on
string      idListSource                  ID of the list to copy into the new list
string      pos                           Position of the list. 'top', 'bottom', or a positive
                                          floating point number

`)
auto postLists(Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/lists`(trelloAPIURL));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Archive all cards in a list
Required Params:
string      id                            The ID of the list

`)
auto postListsArchiveAllCards(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/lists/%s/archiveAllCards`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Move all cards in a list
Required Params:
string      id                            The ID of the list

Query Params:
string      idBoard                       The ID of the board the cards should be moved to
string      idList                        The ID of the list that the cards should be moved to

`)
auto postListsMoveAllCards(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/lists/%s/moveAllCards`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Create a new avatar for a member
Required Params:
string      id                            The ID or username of the member

Query Params:
file        file                          

`)
auto postMembersAvatar(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/avatar`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Upload a new boardBackground
Required Params:
string      id                            The ID or username of the member

Query Params:
file        file                          

`)
auto postMembersBoardBackgrounds(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/boardBackgrounds`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Star a new board
Required Params:
string      id                            The ID or username of the member

Query Params:
string      idBoard                       The ID of the board to star
string      pos                           The position of the newly starred board. 'top', 'bottom', or
                                          a positive float.

`)
auto postMembersBoardStars(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/boardStars`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Upload a new custom emoji
Required Params:
string      id                            The ID or username of the member

Query Params:
file        file                          
string      name                          Name for the emoji. 2 - 64 characters

`)
auto postMembersCustomEmoji(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/customEmoji`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Dismiss a message
Required Params:
string      id                            The ID or username of the member

Query Params:
string      value                         The message to dismiss

`)
auto postMembersOneTimeMessagesDismissed(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/oneTimeMessagesDismissed`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Mark all notifications as read
`)
auto postNotificationsAllRead()
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/notifications/all/read`(trelloAPIURL));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Create a new team
Query Params:
string      displayName                   
string      desc                          The description for the team
string      name                          A string with a length of at least 3. Only lowercase
                                          letters, underscores, and numbers are allowed. Must be
                                          unique.
string      website                       A URL starting with 'http://' or 'https://'

`)
auto postOrganizations(Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations`(trelloAPIURL));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Kick off CSV export for an organization
Required Params:
string      id                            The ID or name of the team

Query Params:
boolean     attachments                   Whether the CSV should include attachments or not.

`)
auto postOrganizationsExports(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/exports`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Set the logo image for a team
Required Params:
string      id                            The ID or name of the team

Query Params:
file        file                          Image file for the logo

`)
auto postOrganizationsLogo(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/logo`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Create a new collection in a team
Required Params:
string      id                            The ID or name of the team

Query Params:
string      name                          The name for the new collection

`)
auto postOrganizationsTags(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/tags`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Create a new webhook for a token.
Required Params:
string      token                         

Query Params:
string      description                   A description to be displayed when retrieving information
                                          about the webhook.
string      callbackURL                   The URL that the webhook should POST information to.
string      idModel                       ID of the object to create a webhook on.

`)
auto postTokensWebhooks(string token, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/tokens/%s/webhooks`(trelloAPIURL,token));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Create a new webhook.
Query Params:
string      description                   A string with a length from '0' to '16384'.
string      callbackURL                   A valid URL that is reachable with a 'HEAD' and 'POST'
                                          request.
string      idModel                       ID of the model to be monitored
boolean     active                        Determines whether the webhook is active and sending 'POST'
                                          requests.

`)
auto postWebhooks(Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/webhooks/`(trelloAPIURL));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Upload a new custom sticker
Required Params:
string      id                            The ID or username of the member

Query Params:
file        file                          

`)
auto postmembersUploadedStickers(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/customStickers`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().post(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Update a comment action
Required Params:
string      id                            The ID of the action to update

Query Params:
string      text                          The new text for the comment

`)
void putActions(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/actions/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update a comment action
Required Params:
string      id                            The ID of the action to update

Query Params:
string      value                         The new text for the comment

`)
void putActionsText(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/actions/%s/text`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update an existing board by id
Required Params:
string      id                            The id of the board to update

Query Params:
string      name                          The new name for the board. 1 to 16384 characters long.
string      desc                          A new description for the board, 0 to 16384 characters long
boolean     closed                        Whether the board is closed
boolean     subscribed                    Whether the acting user is subscribed to the board
string      idOrganization                The id of the team the board should be moved to
string      prefs_permissionLevel         One of: org, private, public
boolean     prefs_selfJoin                Whether team members can join the board themselves
boolean     prefs_cardCovers              Whether card covers should be displayed on this board
boolean     prefs_hideVotes               Determines whether the Voting Power-Up should hide who voted
                                          on cards or not.
string      prefs_invitations             Who can invite people to this board. One of: admins,
                                          members
string      prefs_voting                  Who can vote on this board. One of disabled, members,
                                          observers, org, public
string      prefs_comments                Who can comment on cards on this board. One of: disabled,
                                          members, observers, org, public
string      prefs_background              The id of a custom background or one of: blue, orange,
                                          green, red, purple, pink, lime, sky, grey
string      prefs_cardAging               One of: pirate, regular
boolean     prefs_calendarFeedEnabled     Determines whether the calendar feed is enabled or not.
string      labelNames_green              Name for the green label. 1 to 16384 characters long
string      labelNames_yellow             Name for the yellow label. 1 to 16384 characters long
string      labelNames_orange             Name for the orange label. 1 to 16384 characters long
string      labelNames_red                Name for the red label. 1 to 16384 characters long
string      labelNames_purple             Name for the purple label. 1 to 16384 characters long
string      labelNames_blue               Name for the blue label. 1 to 16384 characters long

`)
void putBoards(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update an existing board by id
Required Params:
string      id                            The id of the board to update
string      type                          Valid values: admin, normal, observer. Determines what type
                                          of member the user being added should be of the board.

Optional Params:
string      fullName                      The full name of the user to as a member of the board. Must
                                          have a length of at least 1 and cannot begin nor end with a
                                          space.

Query Params:
string      email                         The email address of a user to add as a member of the
                                          board.

`)
void putBoardsMembers(string id, string type, string fullName = null, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/members`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Add a member to the board.
Required Params:
string      id                            The id of the board to update
string      idMember                      The id of the member to add to the board.

Query Params:
string      type                          One of: admin, normal, observer. Determines the type of
                                          member this user will be on the board.
boolean     allowBillableGuest            Optional param that allows organization admins to add
                                          multi-board guests onto a board.

`)
void putBoardsMembers(string id, string idMember, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/members/%s`(trelloAPIURL,id,idMember));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update an existing board by id
Required Params:
string      id                            The id of the board to update
string      idMembership                  The id of a membership that should be added to this board.

Query Params:
string      type                          One of: admin, normal, observer. Determines the type of
                                          member that this membership will be to this board.
string      member_fields                 Valid values: all, avatarHash, bio, bioData, confirmed,
                                          fullName, idPremOrgsAdmin, initials, memberType, products,
                                          status, url, username

`)
void putBoardsMemberships(string id, string idMembership, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/memberships/%s`(trelloAPIURL,id,idMembership));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update an existing board by id
Required Params:
string      id                            The id of the board to update

Query Params:
string      value                         Valid values: bottom, top. Determines the position of the
                                          email address.

`)
void putBoardsMyPrefsEmailPosition(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/myPrefs/emailPosition`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update an existing board by id
Required Params:
string      id                            The id of the board to update

Query Params:
string      value                         The id of an email list.

`)
void putBoardsMyPrefsIdEmailList(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/myPrefs/idEmailList`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update an existing board by id
Required Params:
string      id                            The id of the board to update

Query Params:
boolean     value                         Determines whether to show the list guide.

`)
void putBoardsMyPrefsShowListGuide(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/myPrefs/showListGuide`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update an existing board by id
Required Params:
string      id                            The id of the board to update

Query Params:
boolean     value                         Determines whether to show the side bar.

`)
void putBoardsMyPrefsShowSidebar(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/myPrefs/showSidebar`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update an existing board by id
Required Params:
string      id                            The id of the board to update

Query Params:
boolean     value                         Determines whether to show sidebar activity.

`)
void putBoardsMyPrefsShowSidebarActivity(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/myPrefs/showSidebarActivity`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update an existing board by id
Required Params:
string      id                            The id of the board to update

Query Params:
boolean     value                         Determines whether to show the sidebar board actions.

`)
void putBoardsMyPrefsShowSidebarBoardActions(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/myPrefs/showSidebarBoardActions`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update an existing board by id
Required Params:
string      id                            The id of the board to update

Query Params:
boolean     value                         Determines whether to show members of the board in the
                                          sidebar.

`)
void putBoardsMyPrefsShowSidebarMembers(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/boards/%s/myPrefs/showSidebarMembers`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Setting, updating, and removing the value for a Custom Field on a card.
Required Params:
string      idCard                        ID of the card that the Custom Field value should be
                                          set/updated for
string      idCustomField                 ID of the Custom Field on the card.
object      value                         An object containing the key and value to set for the card's
                                          Custom Field value. The key used to set the value should
                                          match the type of Custom Field defined.

`)
void putCardCustomFieldItem(string idCard, string idCustomField, Variable[string] value)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/card/%s/customField/%s/item`(trelloAPIURL,idCard,idCustomField));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update a card
Required Params:
string      id                            The ID of the card to update

Query Params:
string      name                          The new name for the card
string      desc                          The new description for the card
boolean     closed                        Whether the card should be archived (closed: true)
string      idMembers                     Comma-separated list of member IDs
string      idAttachmentCover             The ID of the image attachment the card should use as its
                                          cover, or null for none
string      idList                        The ID of the list the card should be in
string      idLabels                      Comma-separated list of label IDs
string      idBoard                       The ID of the board the card should be on
string      pos                           The position of the card in its list. 'top', 'bottom', or a
                                          positive float
datetime    due                           When the card is due, or 'null'
boolean     dueComplete                   Whether the due date should be marked complete
boolean     subscribed                    Whether the member is should be subscribed to the card
string      address                       For use with/by the Map Power-Up
string      locationName                  For use with/by the Map Power-Up
string      coordinates                   For use with/by the Map Power-Up. Should be
                                          latitude,longitude

`)
void putCards(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update an existing comment
Required Params:
string      id                            The ID of the card
string      idAction                      The ID of the comment action to update

Query Params:
string      text                          The new text for the comment

`)
void putCardsActionsComments(string id, string idAction, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/actions/%s/comments`(trelloAPIURL,id,idAction));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update an item in a checklist on a card.
Required Params:
string      id                            The ID of the card
string      idCheckItem                   The ID of the checklist item to update

Query Params:
string      name                          The new name for the checklist item
string      state                         One of: 'complete', 'incomplete'
string      idChecklist                   The ID of the checklist this item is in
string      pos                           'top', 'bottom', or a positive float

`)
void putCardsCheckItem(string id, string idCheckItem, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/checkItem/%s`(trelloAPIURL,id,idCheckItem));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update an item in a checklist on a card.
Required Params:
string      idCard                        The ID of the card
string      idCheckItem                   The ID of the checklist item to update
string      idChecklist                   The ID of the item to update.

Query Params:
string      pos                           'top', 'bottom', or a positive float

`)
void putCardsChecklistCheckItem(string idCard, string idCheckItem, string idChecklist, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/checklist/%s/checkItem/%s`(trelloAPIURL,idCard,idChecklist,idCheckItem));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update a sticker on a card
Required Params:
string      id                            The ID of the card
string      idSticker                     The ID of the sticker to update

Query Params:
float       top                           
float       left                          
int         zIndex                        
float       rotate                        

`)
void putCardsStickers(string id, string idSticker, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/cards/%s/stickers/%s`(trelloAPIURL,id,idSticker));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update an existing checklist.
Required Params:
string      id                            ID of a checklist.

Query Params:
string      name                          Name of the new checklist being created. Should be length of
                                          1 to 16384.
string      pos                           Determines the position of the checklist on the card. One
                                          of: 'top', 'bottom', or a positive number.

`)
void putChecklists(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/checklists/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`
Required Params:
string      id                            ID of a checklist.

Query Params:
string      value                         The value to change the checklist name to. Should be a
                                          string of length 1 to 16384.

`)
void putChecklistsName(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/checklists/%s/name`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update a Custom Field definition.
Required Params:
string      id                            ID of the customfield to update.

Optional Params:
string      name                          The name of the Custom Field
float       pos                           New position for the custom field. Can also be 'top' or
                                          'bottom'
boolean     display_cardFront             Whether to display this custom field on the front of cards

`)
void putCustomfields(string id, string name = null, double pos = double.nan, bool display_cardFront = false)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/customfields/%s`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Make member an admin of enterprise.
Required Params:
string      id                            ID of the enterprise to retrieve.
string      idMember                      ID of member to be made an admin of enterprise.

`)
void putEnterprisesAdmins(string id, string idMember)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/enterprises/%s/admins/%s`(trelloAPIURL,id,idMember));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Deactivate a member of an enterprise.
Required Params:
string      id                            ID of the enterprise to retrieve.
string      idMember                      ID of the member to deactive.

Query Params:
boolean     value                         Determines whether the user is deactivated or not.
string      fields                        A comma separated list of any valid values that the [nested
                                          member field resource]() accepts.
string      organization_fields           Any valid value that the [nested organization
                                          resource](https://developers.trello.com/v1.0/reference#organizations-nested-resource)
                                          accepts.
string      board_fields                  Any valid value that the [nested board
                                          resource](https://developers.trello.com/v1.0/reference#boards-nested-resource)
                                          accepts.

`)
void putEnterprisesMembersDeactivated(string id, string idMember, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/enterprises/%s/members/%s/deactivated`(trelloAPIURL,id,idMember));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Transfer an organization to an enterprise.
Required Params:
string      id                            ID of the enterprise to retrieve.

Query Params:
string      idOrganization                ID of organization to be transferred to enterprise.

`)
void putEnterprisesOrganizations(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/enterprises/%s/organizations`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update a label by ID.
Required Params:
string      id                            The id of the label to update

Query Params:
string      name                          The new name for the label
string      color                         The new color for the label. See: [fields](#label-object)
                                          for color options

`)
void putLabels(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/labels/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update the color of a label by ID.
Required Params:
string      id                            The id of the label

Query Params:
string      value                         The new color for the label. See: [fields](#label-object)
                                          for color options.

`)
void putLabelsColor(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/labels/%s/color`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update the name of a label by ID.
Required Params:
string      id                            The id of the label to update

Query Params:
string      value                         The new name for the label

`)
void putLabelsName(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/labels/%s/name`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update the properties of a list
Required Params:
string      id                            The ID of the list to update

Query Params:
string      name                          New name for the list
boolean     closed                        Whether the list should be closed (archived)
string      idBoard                       ID of a board the list should be moved to
string      pos                           New position for the list: 'top', 'bottom', or a positive
                                          floating point number
boolean     subscribed                    Whether the active member is subscribed to this list

`)
void putLists(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/lists/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Archive or unarchive a list
Required Params:
string      id                            The ID of the list

Query Params:
boolean     value                         Set to true to close (archive) the list

`)
void putListsClosed(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/lists/%s/closed`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Move a list to a new board
Required Params:
string      id                            The ID of the list

Query Params:
string      value                         The ID of the board to move the list to

`)
void putListsIdBoard(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/lists/%s/idBoard`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Rename a list
Required Params:
string      id                            The ID of the list

Query Params:
string      value                         The new name for the list

`)
void putListsName(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/lists/%s/name`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Change the position of a list
Required Params:
string      id                            The ID of the list

Query Params:
string      value                         'top', 'bottom', or a positive float

`)
void putListsPos(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/lists/%s/pos`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Set a soft limit for number of cards in the list
Required Params:
string      id                            The ID of the list

Query Params:
int         value                         A number between '0' and '5000' or empty to remove the
                                          limit

`)
void putListsSoftLimit(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/lists/%s/softLimit`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Subscribe or unsubscribe from a list
Required Params:
string      id                            The ID of the list

Query Params:
boolean     value                         'true' to subscribe, 'false' to unsubscribe

`)
void putListsSubscribed(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/lists/%s/subscribed`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update a member
Required Params:
string      id                            The ID or username of the member

Query Params:
string      fullName                      New name for the member. Cannot begin or end with a space.
string      initials                      New initials for the member. 1-4 characters long.
string      username                      New username for the member. At least 3 characters long,
                                          only lowercase letters, underscores, and numbers. Must be
                                          unique.
string      bio                           
string      avatarSource                  One of: 'gravatar', 'none', 'upload'
boolean     prefs_colorBlind              
string      prefs_locale                  
int         prefs_minutesBetweenSummaries '-1' for disabled, '1', or '60'

`)
void putMembers(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update a board background
Required Params:
string      id                            The ID or username of the member
string      idBackground                  The ID of the board background to update

Query Params:
string      brightness                    One of: 'dark', 'light', 'unknown'
boolean     tile                          Whether the background should be tiled

`)
void putMembersBoardBackgrounds(string id, string idBackground, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/boardBackgrounds/%s`(trelloAPIURL,id,idBackground));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update the position of a starred board
Required Params:
string      id                            The ID or username of the member
string      idStar                        The ID of the board star to update

Query Params:
string      pos                           New position for the starred board. 'top', 'bottom', or a
                                          positive float.

`)
void putMembersBoardStars(string id, string idStar, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/members/%s/boardStars/%s`(trelloAPIURL,id,idStar));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update the read status of a notification
Required Params:
string      id                            The ID of the notification

Query Params:
boolean     unread                        

`)
void putNotifications(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/notifications/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update the read status of a notification
Required Params:
string      id                            The ID of the notification

Query Params:
boolean     value                         

`)
void putNotificationsUnread(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/notifications/%s/unread`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update an organization
Required Params:
string      id                            The id or name of the organization to update

Query Params:
string      name                          A new name for the organization. At least 3 lowercase
                                          letters, underscores, and numbers. Must be unique
string      displayName                   A new displayName for the organization. Must be at least 1
                                          character long and not begin or end with a space.
string      desc                          A new description for the organization
string      website                       A URL starting with 'http://', 'https://', or 'null'
string      prefs_associatedDomain        The Google Apps domain to link this org to.
boolean     prefs_externalMembersDisabled Whether non-team members can be added to boards inside the
                                          team
int         prefs_googleAppsVersion       '1' or '2'
string      prefs_boardVisibilityRestrict_orgWho on the team can make team visible boards. One of
                                          'admin', 'none', 'org'
string      prefs_boardVisibilityRestrict_privateWho can make private boards. One of: 'admin', 'none', 'org'
string      prefs_boardVisibilityRestrict_publicWho on the team can make public boards. One of: 'admin',
                                          'none', 'org'
string      prefs_orgInviteRestrict       An email address with optional wildcard characters. (E.g.
                                          'subdomain.*.trello.com')
string      prefs_permissionLevel         Whether the team page is publicly visible. One of:
                                          'private', 'public'

`)
void putOrganizations(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Add a member to a team or update their member type.
Required Params:
string      id                            The ID or name of the organization
string      idMember                      The ID or username of the member to update

Query Params:
string      type                          One of: 'admin', 'normal'

`)
void putOrganizationsMembers(string id, string idMember, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/members/%s`(trelloAPIURL,id,idMember));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`
Required Params:
string      id                            The ID or name of the organization

Query Params:
string      email                         An email address
string      fullName                      Name for the member, at least 1 character not beginning or
                                          ending with a space
string      type                          One of: 'admin', 'normal'

`)
void putOrganizationsMembers(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/members`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Deactivate or reactivate a member of a team
Required Params:
string      id                            The ID or name of the organization
string      idMember                      The ID or username of the member to update

Query Params:
boolean     value                         

`)
void putOrganizationsMembersDeactivated(string id, string idMember, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/organizations/%s/members/%s/deactivated`(trelloAPIURL,id,idMember));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update an existing webhook.
Required Params:
string      token                         The token to which the webhook belongs
string      webhookId                     ID of the webhook to update

Query Params:
string      description                   A description to be displayed when retrieving information
                                          about the webhook.
string      callbackURL                   The URL that the webhook should POST information to.
string      idModel                       ID of the object to create a webhook on.

`)
void putTokensWebhooks(string token, string webhookId, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/tokens/%s/webhooks/%s`(trelloAPIURL,token,webhookId));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Update a webhook by ID.
Required Params:
string      id                            ID of the webhook to update.

Query Params:
string      description                   A string with a length from '0' to '16384'.
string      callbackURL                   A valid URL that is reachable with a 'HEAD' and 'POST'
                                          request.
string      idModel                       ID of the model to be monitored
boolean     active                        Determines whether the webhook is active and sending 'POST'
                                          requests.

`)
void putWebhooks(string id, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/webhooks/%s`(trelloAPIURL,id));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	newRequest().put(url,queryParams.queryParamMap);
}


@SILdoc(`Find what you're looking for in Trello
Query Params:
string      query                         The search query with a length of 1 to 16384 characters
string      idBoards                      mine or a comma-separated list of board ids
string      idOrganizations               A comma-separated list of team ids
string      idCards                       A comma-separated list of card ids
string      modelTypes                    What type or types of Trello objects you want to search. all
                                          or a comma-separated list of: actions, boards, cards,
                                          members, organizations
string      board_fields                  all or a comma-separated list of: closed, dateLastActivity,
                                          dateLastView, desc, descData, idOrganization, invitations,
                                          invited, labelNames, memberships, name, pinned, powerUps,
                                          prefs, shortLink, shortUrl, starred, subscribed, url
int         boards_limit                  The maximum number of boards returned. Maximum: 1000
string      card_fields                   all or a comma-separated list of: badges, checkItemStates,
                                          closed, dateLastActivity, desc, descData, due, email,
                                          idAttachmentCover, idBoard, idChecklists, idLabels, idList,
                                          idMembers, idMembersVoted, idShort, labels,
                                          manualCoverAttachment, name, pos, shortLink, shortUrl,
                                          subscribed, url
int         cards_limit                   The maximum number of cards to return. Maximum: 1000
int         cards_page                    The page of results for cards. Maximum: 100
boolean     card_board                    Whether to include the parent board with card results
boolean     card_list                     Whether to include the parent list with card results
boolean     card_members                  Whether to include member objects with card results
boolean     card_stickers                 Whether to include sticker objects with card results
string      card_attachments              Whether to include attachment objects with card results. A
                                          boolean value (true or false) or cover for only card cover
                                          attachments.
string      organization_fields           all or a comma-separated list of billableMemberCount, desc,
                                          descData, displayName, idBoards, invitations, invited,
                                          logoHash, memberships, name, powerUps, prefs,
                                          premiumFeatures, products, url, website
int         organizations_limit           The maximum number of teams to return. Maximum 1000
string      member_fields                 all or a comma-separated list of: avatarHash, bio, bioData,
                                          confirmed, fullName, idPremOrgsAdmin, initials, memberType,
                                          products, status, url, username
int         members_limit                 The maximum number of members to return. Maximum 1000
boolean     partial                       By default, Trello searches for each word in your query
                                          against exactly matching words within Member content.
                                          Specifying partial to be true means that we will look for
                                          content that starts with any of the words in your query. If
                                          you are looking for a Card titled "My Development Status
                                          Report", by default you would need to search for
                                          "Development". If you have partial enabled, you will be able
                                          to search for "dev" but not "velopment".

`)
auto search(Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/search`(trelloAPIURL));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Search for Trello members
Query Params:
string      query                         Search query 1 to 16384 characters long
int         limit                         The maximum number of results to return. Maximum of 20.
string      idBoard                       
string      idOrganization                
boolean     onlyOrgMembers                

`)
auto searchMembers(Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/search/members/`(trelloAPIURL));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Retrieve information about a token.
Required Params:
string      token                         

Query Params:
string      fields                        'all' or a comma-separated list of 'dateCreated',
                                          'dateExpires', 'idMember', 'identifier', 'permissions'
boolean     webhooks                      Determines whether to include webhooks.

`)
auto tokens(string token, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/tokens/%s`(trelloAPIURL,token));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Retrieve information about a token's owner by token.
Required Params:
string      token                         

Query Params:
string      fields                        'all' or a comma-separated list of valid fields for [Member
                                          Object](ref:member-object).

`)
auto tokensMember(string token, Variable[string] queryParams = (Variable[string]).init)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/tokens/%s/member`(trelloAPIURL,token));
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Retrieve all webhooks created with a token.
Required Params:
string      token                         

`)
auto tokensWebhooks(string token)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/tokens/%s/webhooks`(trelloAPIURL,token));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Retrieve a webhook created with a token.
Required Params:
string      token                         
string      idWebhook                     ID of the [Webhooks](ref:webhooks) to retrieve.

`)
auto tokensWebhooks(string token, string idWebhook)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/tokens/%s/webhooks/%s`(trelloAPIURL,token,idWebhook));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a webhook by ID.
Required Params:
string      id                            ID of the webhook to retrieve.

`)
auto webhooks(string id)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/webhooks/%s`(trelloAPIURL,id));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


@SILdoc(`Get a webhook's field.
Required Params:
string      id                            ID of the webhook.
string      field                         Field to retrieve. One of: 'active', 'callbackURL',
                                          'description', 'idModel'

`)
auto webhooks(string id, string field)
{
	import requests;
	import std.uri: encode;
	import std.array: array;
	import std.format: format;

	auto url = encode(format!`%s/1/webhooks/%s/%s`(trelloAPIURL,id,field));
	Variable[string] queryParams;
	queryParams["key"] = Variable(trelloSecret);
	queryParams["token"] = Variable(trelloAuth);
	auto result = cast(string) (newRequest().get(url,queryParams.queryParamMap).responseBody.array);
	return result.asVariable;
}


// FIN