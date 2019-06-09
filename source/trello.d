import asdf: Asdf;

enum targetFile = "trellogen.d";

int main(string[] args)
{
	static import std.file;
	import std.string:strip;
	import std.algorithm:filter;
	import std.conv:to;
	import asdf:parseJson;
	import std.stdio:stderr,writefln;

	auto actions = getAPIInfo("https://developers.trello.com/reference");
	auto json = parseJson(actions);
	std.file.write("trello.json",json.to!string);
	auto apis = parseAPI(json);
	std.file.write(targetFile,apis.generateAPI);
	stderr.writefln("success");
	return 0;
}

string getAPIInfo(string url)
{
	import arrogant:Arrogant;
	import std.net.curl:get;
	auto arrogant = Arrogant();
	auto apidoc = get(url).idup;
	auto tree = arrogant.parse(apidoc);
	auto actions = tree.byClass("hub-content-container").front.byId("docs").front["data-json"].get;
	return actions;
}

string generateRegisterHandlerHelper(ApiCall[] apis)
{
	import std.array:Appender,array;
	import std.algorithm:map,sort,uniq;
	import std.string:join,leftJustify,wrap,splitLines;
	import std.format:format;
	Appender!string ret;

	auto apiText = apis
						.map!(api => (api.description ~ ",").leftJustify(28))
						.array
						.sort
						.uniq
						.join(" ")
						.wrap(80)
						.splitLines
						.map!(line => "\t\t" ~ line)
						.array
						.join("\n");
	ret.put(format!
q{
private void registerHandlerHelper(ref Handlers handlers)
{
	static foreach(F;AliasSeq!(
%s
	))
	{
		handlers.registerHandler!F;
	}
}

}	(apiText));
	return ret.data;
}

string generateAPI(ApiCall[] apis)
{
	import std.algorithm:map,filter;
	import std.string:join,strip;
	import std.array:Appender,array;
	Appender!string ret;

	apis = apis.filter!(api => api.url.strip.length > 0).array;
	ret.put(CodePrelude);
	ret.put(apis.generateRegisterHandlerHelper);
	ret.put(apis.map!(api => api.toD).join('\n'));
	ret.put("\n// FIN");
	return ret.data;
}

ApiCall[] parseAPI(ref Asdf json)
{
	import std.range:put;
	ApiCall[] ret;

	foreach(el;json.byElement)
	{
		foreach(c;el["children"].byElement)
		{
			auto apiCall = ApiCall(c);
			ret ~= apiCall;
		}
	}
	return ret;
}

struct ResultCodeEntry
{
	string id;
	string description;
	string idModel;
	string callbackURL;
	bool active;
	string name;
	string json;

	this(string s)
	{
		import std.string:strip;
		s = s.strip;
		if(s.length==0)
			return;
		this.json = s;
	}
}

struct ResultCode
{
	int status;
	string language;
	ResultCodeEntry code;

	this(ref Asdf el)
	{
		status = el["status"].get!int(0);
		language=el["language"].get!string("");
		code = el["code"].get!string("{}").ResultCodeEntry;
	}
}


enum CodeApiImports =
q{
	import requests;
	import std.uri:encode;
	import std.array:array;
};

enum CodePrelude =
q{
module kaleidic.sil.std.extra.trello;

import kaleidic.sil.lang.handlers:Handlers;
import kaleidic.sil.lang.types: Variable, SILdoc;

shared string trelloAPIURL = "https://api.trello.com";
shared string trelloSecret, trelloAuth;

void registerTrello(Handlers handlers)
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
	if (apiKey.length == 0) apiKey = environment.get("TRELLO_API_KEY","");
	return format!"https://trello.com/1/authorize?expiration=%s&name=%s&scope=%s&response_type=token&key=%s"
			(expiration,name,tokenScope,apiKey);
}


void openBrowserAuth(string apiKey="", string tokenScope = "read,write,account", string name = "Sil", string expiration = "never")
{
	import std.process: environment;
	if (apiKey.length == 0) apiKey = environment.get("TRELLO_API_KEY","");
	import kaleidic.sil.std.core.process:openBrowser;
	auto uri = createTokenURI(apiKey,tokenScope,name,expiration);
	openBrowser(uri);
}

@SILdoc("set Trello secrets from TRELLO_SECRET and TRELLO_AUTH environmental variables")
string setSecrets()
{
	import std.process: environment;
	trelloSecret = environment.get("TRELLO_API_KEY","");
	trelloAuth = environment.get("TRELLO_AUTH","");
	return "Secret has been set to TRELLO_API_KEY and auth to TRELLO_AUTH environment variables";
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
	result = result[0.100].strip;
	return result.startsWith("{") || result.startsWith("[");
}

private Variable asVariable(string result)
{
	import kaleidic.sil.std.core.util:dslParseJson;
	return (result.length > 0 && result.isJson) ? dslParseJson(result) : Variable.init;
}

};

string toD(ApiCall call)
{
	import std.array:Appender;
	import std.algorithm:filter;
	import std.format:format;

	Appender!string ret;
	ret.put(call.getSilDoc());
	ret.put(call.getPrototype());
	ret.put("\n{");
	ret.put(CodeApiImports);
	ret.put("\n");
	ret.put("	auto url = encode(" ~ generateUrlD(call) ~ ");");
	//format!"%s/1/search/?query=%s%s&key=%s&token=%s"(trelloAPIURL,query,queryParamString,trelloSecret,trelloAuth));`);
	ret.put("\n");
	ret.put(format!"	auto result = cast(string) (Request().%s(url).responseBody.array);\n"(call.method));
	ret.put("\treturn result.asVariable;");
	ret.put("\n}\n");
	ret.put("\n");
	return ret.data;
}

string replaceSwaggerToken(string url)
{
	import std.string:indexOf;
	auto i = url.indexOf("{");
	if (i==-1)
		return url;
	auto j = url[i+1..$].indexOf("}");
	if (j==-1)
		return url;
	return replaceSwaggerToken(url[0..i] ~ "%s" ~ url[i+1+j+1..$]);
}

string generateUrlD(ApiCall call, bool includeQueryParam = true)
{
	import std.string:split,join;
	import std.format:format;
	import std.algorithm:filter,map;
	import std.array:Appender,array;
	Appender!string ret;
	auto names = call.url.split("/").filter!(tok => tok.length>3 && tok[0]=='{').map!(tok=>tok[1..$-1]).array;
	names = "trelloAPIURL" ~ names;
	auto url = call.url.replaceSwaggerToken;
	ret.put("format!`");
	ret.put(`%s/1`);
	ret.put(url);
	if (includeQueryParam)
	{
		ret.put("%s");
		names= names ~ "queryParams.queryParamString";
	}
	ret.put("`(");
	ret.put(names.join(","));
	ret.put(")");
	return ret.data;
}

string prettyParams(Param[] params)
{
	import std.string:leftJustify,wrap,join;
	import std.format:format;
	import std.array:Appender,array;
	import std.string:splitLines,strip,replace;
	import std.algorithm:filter;
	import std.range:repeat;
	import std.conv:to;

	Appender!string ret;

	foreach(param;params)
	{
		auto desc = param.desc.replaceBackTick.splitLines.join(' ').wrap(60).leftJustify(60).splitLines.filter!(line=>line.strip.length>0).array;
		auto firstDesc = (desc.length == 0) ? "" : desc[0];
		ret.put(format!"%s%s%s\n"(
												param.type.to!string.stripTrailingUnderline.leftJustify(12),
												param.name.replace("/","_").leftJustify(30),
												firstDesc));
		if(desc.length>1)
		{
			foreach(descLine;desc[1..$])
			{
				ret.put(format!"%s%s\n"(' '.repeat(42),descLine));
			}
		}
	}
	return ret.data;
}

string getSilDocParamsHelper(string title, Param[] params)
{
	import std.array:Appender;
	Appender!string ret;

	if(params.length>0)
	{
		ret.put("\n");
		ret.put(title);
		ret.put(":\n");
		ret.put(prettyParams(params).replaceBackTick);
	}
	return ret.data;
}

string getSilDoc(ApiCall call)
{
	import std.array:Appender,array;
	import std.algorithm:filter;
	import std.format:format;
	import std.string:strip;

	Appender!string ret;
	Appender!string finalRet;

	ret.put(call.excerpt);
	auto requiredParams = call.params.filter!(param => (param.required && !(param.in_ == "query"))).array;
	auto optionalParams = call.params.filter!(param => (!param.required && !(param.in_ == "query"))).array;
	auto queryParams = call.params.filter!(param => param.in_ == "query").array;

	ret.put(getSilDocParamsHelper("Required Params",requiredParams));
	ret.put(getSilDocParamsHelper("Optional Params",optionalParams));
	ret.put(getSilDocParamsHelper("Query Params",queryParams));

	if (ret.data.strip.length > 0)
	{
		finalRet.put("@SILdoc(`");
		finalRet.put(ret.data);
		finalRet.put("\n`)\n");
	}
	return finalRet.data;
}

string stripTrailingUnderline(string s)
{
	return (s.length<1 || s[$-1]!='_') ? s: s[0..$-1];
}

string replaceBackTick(string s)
{
	import std.string:replace;
	return s.replace("`","'");
}

string getPrototype(ApiCall call)
{
	import std.array:Appender,array;
	import std.algorithm:filter,map;
	import std.string:join;

	Appender!string ret;

	ret.put("auto ");
	ret.put(call.description);
	ret.put("(");
	auto requiredParams = call.params.filter!(param => (param.required && !(param.in_ == "query"))).array;
	auto optionalParams = call.params.filter!(param => (!param.required && !(param.in_ == "query"))).array;
	auto queryParams = call.params.filter!(param => param.in_ == "query").array;
	auto params = requiredParams.map!(param=>param.toD).array ~
				 optionalParams.map!(param=>param.toD).array;
	if(queryParams.length > 0)
		params ~= ["Variable[string] queryParams = Variable[string].init"];
	ret.put(params.join(", "));
	ret.put(")");
	return ret.data;
}

struct ApiCall
{
	string slug;
	string excerpt;
	string type;
	string swaggerPath;
	string url;
	string method;
	string returnType;
	bool authRequired;
	Param[] params;
	string[] codeExamples;
	ResultCode[] codes;
	string[] urlArgs;

	this(ref Asdf c)
	{
		import std.algorithm:canFind,countUntil,filter,map;
		import std.string:split;
		import std.array:array;

		slug = c["slug"].get!string("");
		excerpt=c["excerpt"].get!string("");
		type=c["type"].get!string("");
		swaggerPath=c["swagger"]["path"].get!string("");
		auto el = c["api"];
		this.url = el["url"].get!string("");
		this.method=el["method"].get!string("");
		this.returnType = "";
		this.params = el["params"].byElement.map!(p=>Param(p)).array;

		urlArgs = url.split("/")
						.filter!(part => part.length > 3 && part[0]=='{')
						.map!(part => part[1..$-1])
						.array;
		foreach(arg;urlArgs)
		{
			auto i =this.params.countUntil!(param => param.name==arg);
			if (i!=-1)
				this.params[i].required=true;
		}
		this.authRequired = el["auth"].get!string("") == "required";
		this.codes = el["results"]["codes"].byElement.map!(c => ResultCode(c)).array;
		/+
		auto examples = el["examples"];
		foreach(example;examples.byKeyValue)
		{
			if(example.key=="codes")
				this.codeExamples~=example.value.byElement.map!(e => e.get!string("")).array;
		}
		+/
	}
	string description()
	{
		import std.array:Appender;
		import std.string:toLower,capitalize,split,replace;
		Appender!string ret;

		ret.put(method.toLower.replace("put","set").replace("post","set"));
		auto tokens = swaggerPath.replace("s/{","/{").stripSwaggerParams.split("/");
		if (tokens.length==0)
		{
			ret.put(slug.replace("-","_"));
			return ret.data.removeGet();
		}
		foreach(token;tokens)
		{
			ret.put(token.capitalizeFirst);
		}
		return ret.data.removeGet();
	}
}

string removeGet(string s)
{
	import std.string:startsWith;
	return (s.startsWith("get")) ?  s[3..$].decapitalize : s;
}

string decapitalize(string s)
{
	import std.string:toLower;
	if (s.length <2)
		return s;
	return [s[0]].toLower ~ s[1..$];
}

string capitalizeFirst(string s)
{
	import std.string:toUpper;
	if (s.length <2)
		return s;
	return [s[0]].toUpper~ s[1..$];
}

string stripSwaggerParams(string s)
{
	string ret;
	bool inParam = false;
	foreach(c;s)
	{
		if(c=='{')
		{
			inParam=true;
			ret~="/";
		}
		if (!inParam)
			ret~=c;
		if (c=='}')
			inParam=false;
	}
	return ret;
}


struct Param
{
	string id;
	string ref_;
	ParamType type;
	string in_;
	bool required;
	string desc;
	string defaultValue;
	string name;

	this(Asdf el)
	{
		this.id=el["id"].get!string("");
		this.in_=el["in"].get!string("");
		this.type=el["type"].get!string("").parseParamType;
		this.in_=el["in"].get!string("");
		this.required=el["required"].get!bool(false);
		this.desc=el["desc"].get!string("");
		this.defaultValue = el["defaultValue"].get!string("");
		this.name = el["name"].get!string("");
	}
	string defaultValueD()
	{
		import std.format:format;

		final switch(type) with(ParamType)
		{
			case boolean:
				return defaultValue == "true" ? "true":"false";
			case datetime:
				return defaultValue.length ==0 ? "DateTime.init" : "DateTime.init"; // FIXME should parse defaultValue
			case file:
				return defaultValue.length == 0 ? "null": format!`"%s"`(defaultValue);
			case float_:
				return defaultValue.length ==0 ? "double.nan" : defaultValue;
			case int_:
				return defaultValue.length == 0 ? "0L": defaultValue;
			case object_:
				return defaultValue.length ==0 ? "Variable[string].init" : defaultValue;
			case array_:
				return defaultValue.length ==0 ? "[]": defaultValue;
			case string_:
				return defaultValue.length ==0 ? "null": format!`"%s"`(defaultValue);
		}
	}
}

string toD(Param param)
{
	import std.string:replace;
	import std.array:Appender;
	Appender!string ret;

	ret.put(param.type.toD);
	ret.put(" ");
	ret.put(param.name.replace("/","_"));
	if(!param.required)
		ret.put(" = " ~ param.defaultValueD);
	return ret.data;
}


ParamType parseParamType(string s)
{
	import std.conv:to;
	import std.traits:EnumMembers;
	static foreach(T; EnumMembers!ParamType)
	{
		if (T.to!string.stripTrailingUnderline == s)
			return T;
	}
	return ParamType.object_;
}

enum ParamType
{
	boolean,
	datetime,
	file,
	float_,
	int_,
	object_,
	array_,
	string_,
}

string toD(ParamType type)
{
	final switch(type) with (ParamType)
	{
		case boolean:
			return "bool";
		case datetime:
			return "DateTime";
		case file:
			return "string";
		case float_:
			return "double";
		case int_:
			return "long";
		case object_:
			return "Variable[string]";
		case array_:
			return "Variable[]";
		case string_:
			return "string";
	}
}

